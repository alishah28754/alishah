const pool = require('../config/db');
const cloudinary = require('../config/cloudinary');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { sendPushToMysqlUser } = require('../utils/pushNotifications');

/**
 * Maps DB rows to EXACT shape expected by Flutter's Order.fromJson()
 */
function toOrderJson(orderRow, itemRows) {
  return {
    id: orderRow.id,
    date: orderRow.created_at,
    items: orderRow.item_count || itemRows.reduce((sum, i) => sum + i.quantity, 0),
    total: orderRow.total,
    status: orderRow.status,
    payment: orderRow.payment_method,
    tracking: orderRow.tracking_id || '',
    image: orderRow.thumbnail || (itemRows[0] ? itemRows[0].image_url : ''),
    transaction_screenshot_url: orderRow.transaction_screenshot_url || '',
    orderItems: itemRows.map((i) => ({
      name: i.name,
      price: i.price,
      quantity: i.quantity,
      imageUrl: i.image_url,
    })),
  };
}

function generateOrderId() {
  const date = new Date();
  const ymd = date.toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `KTEX-${ymd}-${rand}`;
}

function generateTrackingId() {
  return `TRK${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

const PAYMENT_METHOD_MAP = {
  cod: 'cod',
  easypaisa: 'easypaisa',
  jazzcash: 'jazzcash',
  bank: 'bank_transfer',
  bank_transfer: 'bank_transfer',
};

function mapPaymentMethod(value) {
  return PAYMENT_METHOD_MAP[value] || 'cod';
}

/**
 * POST /api/orders/upload-screenshot
 */
const uploadOrderScreenshot = asyncHandler(async (req, res) => {
  if (!req.file) {
    return error(res, 'No screenshot file provided.', 400);
  }

  const uploadResult = await new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: 'ktex/orders' },
      (err, result) => (err ? reject(err) : resolve(result))
    );
    stream.end(req.file.buffer);
  });

  return success(
    res,
    { url: uploadResult.secure_url, path: uploadResult.public_id },
    'Screenshot uploaded.'
  );
});

/**
 * POST /api/orders - Create order (guest or logged-in)
 */
const createOrder = asyncHandler(async (req, res) => {
  const {
    items,
    name, email, phone, address, city, zip,
    payment_method, transaction_id, account_title, account_number,
    transaction_screenshot_url,
  } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return error(res, 'items array is required.', 400);
  }
  if (!name || !phone || !address || !city) {
    return error(res, 'name, phone, address and city are required.', 400);
  }

  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const deliveryFee = subtotal >= 5000 ? 0 : 300;
  const total = subtotal + deliveryFee;
  const itemCount = items.reduce((sum, i) => sum + i.quantity, 0);
  const thumbnail = items[0] ? items[0].image_url || null : null;

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const orderId = generateOrderId();
    const trackingId = generateTrackingId();

    await connection.query(
      `INSERT INTO orders
        (id, tracking_id, user_id, full_name, email, phone, address, city, zip,
         payment_method, transaction_id, account_title, account_number,
         transaction_screenshot_url,
         subtotal, delivery_fee, total, status, item_count, thumbnail)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Processing', ?, ?)`,
      [
        orderId, trackingId, req.user ? req.user.id : null, name, email || null, phone, address, city, zip || null,
        mapPaymentMethod(payment_method), transaction_id || null, account_title || null, account_number || null,
        transaction_screenshot_url || null,
        subtotal, deliveryFee, total, itemCount, thumbnail,
      ]
    );

    for (const item of items) {
      const productId = item.product_id || null;
      await connection.query(
        `INSERT INTO order_items (order_id, product_id, name, price, quantity, image_url)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [orderId, productId, item.name, item.price, item.quantity, item.image_url || null]
      );
    }

    if (req.user) {
      await connection.query('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);
    }

    await connection.commit();

    const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [orderId]);

    if (req.user) {
      sendPushToMysqlUser(req.user.id, {
        title: 'Order placed! 🛍️',
        body: `Your order ${orderId} has been received and is being processed.`,
        data: { orderId, status: 'Processing', type: 'order_update' },
      });
    }

    return success(res, toOrderJson(orderRows[0], itemRows), 'Order placed successfully.', 201);
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
});

/**
 * GET /api/orders/my-orders - Current user's orders
 */
const getMyOrders = asyncHandler(async (req, res) => {
  const [orders] = await pool.query(
    'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
    [req.user.id]
  );

  const results = [];
  for (const order of orders) {
    const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
    results.push(toOrderJson(order, itemRows));
  }
  return success(res, results);
});

/**
 * GET /api/orders/track/:orderNumber - Public tracking
 */
const trackOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found. Check your order number.', 404);

  const order = orders[0];
  const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
  return success(res, toOrderJson(order, itemRows));
});

/**
 * PUT /api/orders/:orderNumber/cancel - Cancel order
 */
const cancelOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found.', 404);

  const order = orders[0];

  if (order.user_id !== null) {
    if (!req.user || order.user_id !== req.user.id) {
      return error(res, 'You do not have access to this order.', 403);
    }
  }

  if (order.status !== 'Processing') {
    return error(res, `Order cannot be cancelled once it is ${order.status}.`, 400);
  }

  await pool.query("UPDATE orders SET status = 'Cancelled' WHERE id = ?", [order.id]);
  
  if (order.user_id) {
    sendPushToMysqlUser(order.user_id, {
      title: 'Order Cancelled',
      body: `Your order ${order.id} has been cancelled.`,
      data: { orderId: order.id, status: 'Cancelled', type: 'order_update' },
    });
  }
  
  return success(res, null, 'Order cancelled.');
});

/**
 * DELETE /api/orders/:orderNumber - Permanently delete order
 */
const deleteOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found.', 404);

  const order = orders[0];
  const isAdmin = !!(req.user && req.user.is_admin);

  if (!isAdmin && order.user_id !== null) {
    if (!req.user || order.user_id !== req.user.id) {
      return error(res, 'You do not have access to this order.', 403);
    }
  }

  if (!['Cancelled', 'Delivered'].includes(order.status)) {
    return error(res, 'Only cancelled or delivered orders can be deleted.', 400);
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('DELETE FROM order_items WHERE order_id = ?', [order.id]);
    await connection.query('DELETE FROM orders WHERE id = ?', [order.id]);
    await connection.commit();
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }

  return success(res, null, 'Order deleted permanently.');
});

/**
 * ✅ PUT /api/orders/:orderNumber/status - Update order status (Admin only)
 */
const updateOrderStatus = asyncHandler(async (req, res) => {
  const { orderNumber } = req.params;
  const { status } = req.body;

  const allowedStatuses = ['Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded'];
  if (!allowedStatuses.includes(status)) {
    return error(res, 'Invalid status value. Allowed: ' + allowedStatuses.join(', '), 400);
  }

  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderNumber]);
  if (orders.length === 0) {
    return error(res, 'Order not found.', 404);
  }

  const order = orders[0];
  await pool.query('UPDATE orders SET status = ? WHERE id = ?', [status, orderNumber]);

  if (order.user_id) {
    const statusMessages = {
      'Processing': 'Your order has been confirmed and is being processed.',
      'Shipped': 'Your order has been shipped! 🚚',
      'Delivered': 'Your order has been delivered successfully! ✅',
      'Cancelled': 'Your order has been cancelled.',
      'Refunded': 'Your order has been refunded.'
    };

    await sendPushToMysqlUser(order.user_id, {
      title: `Order ${status}`,
      body: statusMessages[status] || `Your order ${orderNumber} status updated to ${status}`,
      data: { 
        orderId: orderNumber, 
        status: status, 
        type: 'order_update' 
      },
    });

    console.log(`🔔 [Order] Push notification sent to user ${order.user_id} for order ${orderNumber} status: ${status}`);
  }

  return success(res, { orderNumber, status }, `Order status updated to ${status}`);
});

/**
 * ✅ GET /api/orders/admin/all - Get all orders (Admin only)
 */
const getAllOrders = asyncHandler(async (req, res) => {
  const [orders] = await pool.query(`
    SELECT 
      o.*,
      u.full_name as customer_name,
      u.email as customer_email,
      u.phone as customer_phone
    FROM orders o
    LEFT JOIN users u ON o.user_id = u.id
    ORDER BY o.created_at DESC
  `);

  return success(res, orders);
});

// ✅ EXPORT ALL FUNCTIONS
module.exports = {
  createOrder,
  getMyOrders,
  trackOrder,
  cancelOrder,
  deleteOrder,
  uploadOrderScreenshot,
  updateOrderStatus,
  getAllOrders,
  toOrderJson,
};
