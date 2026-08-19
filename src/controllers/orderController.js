const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

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

// Flutter sends 'bank' for Bank Transfer, but the DB enum expects 'bank_transfer'.
// Map any incoming payment method to the exact enum value stored in `orders`.
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
 * POST /api/orders - Create order (guest or logged-in)
 */
const createOrder = asyncHandler(async (req, res) => {
  const {
    items, // [{ product_id (string), name, price, quantity, image_url }]
    name, email, phone, address, city, zip,
    payment_method, transaction_id, account_title, account_number,
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

    // Insert order
    await connection.query(
      `INSERT INTO orders
        (id, tracking_id, user_id, full_name, email, phone, address, city, zip,
         payment_method, transaction_id, account_title, account_number,
         subtotal, delivery_fee, total, status, item_count, thumbnail)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Processing', ?, ?)`,
      [
        orderId, trackingId, req.user ? req.user.id : null, name, email || null, phone, address, city, zip || null,
        mapPaymentMethod(payment_method), transaction_id || null, account_title || null, account_number || null,
        subtotal, deliveryFee, total, itemCount, thumbnail,
      ]
    );

    // Insert order items - accepts string product_id
    for (const item of items) {
      const productId = item.product_id || null;
      await connection.query(
        `INSERT INTO order_items (order_id, product_id, name, price, quantity, image_url)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [orderId, productId, item.name, item.price, item.quantity, item.image_url || null]
      );
    }

    // Clear cart if logged in
    if (req.user) {
      await connection.query('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);
    }

    await connection.commit();

    const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [orderId]);

    return success(res, toOrderJson(orderRows[0], itemRows), 'Order placed successfully.', 201);
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
});

/** GET /api/orders - Current user's orders */
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

/** GET /api/orders/track/:orderNumber - Public tracking */
const trackOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found. Check your order number.', 404);

  const order = orders[0];
  const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
  return success(res, toOrderJson(order, itemRows));
});

/** PUT /api/orders/:orderNumber/cancel - Cancel order (owner only) */
const cancelOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found.', 404);

  const order = orders[0];
  if (order.user_id !== req.user.id) return error(res, 'You do not have access to this order.', 403);
  if (order.status !== 'Processing') {
    return error(res, `Order cannot be cancelled once it is ${order.status}.`, 400);
  }

  await pool.query("UPDATE orders SET status = 'Cancelled' WHERE id = ?", [order.id]);
  return success(res, null, 'Order cancelled.');
});

/**
 * DELETE /api/orders/:orderNumber - Permanently delete an order (owner only).
 * Only allowed once the order is already 'Cancelled' (mirrors the app UI,
 * which only shows the "Delete" button on cancelled orders). This removes
 * the order from the DB entirely, so it also disappears from the admin
 * panel automatically since both read the same `orders` table.
 */
const deleteOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found.', 404);

  const order = orders[0];
  if (order.user_id !== req.user.id) return error(res, 'You do not have access to this order.', 403);
  if (order.status !== 'Cancelled') {
    return error(res, 'Only cancelled orders can be deleted.', 400);
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

module.exports = {
  createOrder,
  getMyOrders,
  trackOrder,
  cancelOrder,
  deleteOrder,
  toOrderJson,
};
