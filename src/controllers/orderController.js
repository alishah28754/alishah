const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Maps DB rows to EXACT shape expected by Flutter's Order.fromJson()
 */
function toOrderJson(orderRow, itemRows) {
  return {
    id: orderRow.order_number,
    date: orderRow.created_at,
    items: itemRows.reduce((sum, i) => sum + i.quantity, 0),
    total: orderRow.total,
    status: orderRow.status,
    payment: orderRow.payment_method,
    tracking: orderRow.tracking_number || '',
    image: itemRows[0] ? itemRows[0].image_url : '',
    orderItems: itemRows.map((i) => ({
      name: i.name,
      price: i.price,
      quantity: i.quantity,
      imageUrl: i.image_url,
    })),
  };
}

function generateOrderNumber() {
  const date = new Date();
  const ymd = date.toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `KTEX-${ymd}-${rand}`;
}

function generateTrackingNumber() {
  return `TRK${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

/**
 * POST /api/orders - Create order (guest or logged-in)
 * FIX: Handles string product IDs from frontend
 */
const createOrder = asyncHandler(async (req, res) => {
  const {
    items, // [{ product_id (string), name, price, quantity, image_url }]
    name, email, phone, address, city, zip,
    payment_method, transaction_id,
  } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return error(res, 'items array is required.', 400);
  }
  if (!name || !email || !phone || !address || !city) {
    return error(res, 'name, email, phone, address and city are required.', 400);
  }

  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const total = subtotal;

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const orderNumber = generateOrderNumber();
    const trackingNumber = generateTrackingNumber();

    // Insert order
    const [orderResult] = await connection.query(
      `INSERT INTO orders
        (order_number, user_id, customer_name, email, phone, address, city, zip,
         payment_method, transaction_id, subtotal, total, status, tracking_number)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Processing', ?)`,
      [
        orderNumber, req.user ? req.user.id : null, name, email, phone, address, city, zip || null,
        payment_method || 'cod', transaction_id || null, subtotal, total, trackingNumber,
      ]
    );

    const orderId = orderResult.insertId;

    // Insert order items - FIX: accepts string product_id
    for (const item of items) {
      // product_id can be string from frontend
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
  const [orders] = await pool.query('SELECT * FROM orders WHERE order_number = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found. Check your order number.', 404);

  const order = orders[0];
  const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
  return success(res, toOrderJson(order, itemRows));
});

/** PUT /api/orders/:orderNumber/cancel - Cancel order (owner only) */
const cancelOrder = asyncHandler(async (req, res) => {
  const [orders] = await pool.query('SELECT * FROM orders WHERE order_number = ?', [req.params.orderNumber]);
  if (orders.length === 0) return error(res, 'Order not found.', 404);

  const order = orders[0];
  if (order.user_id !== req.user.id) return error(res, 'You do not have access to this order.', 403);
  if (order.status !== 'Processing') {
    return error(res, `Order cannot be cancelled once it is ${order.status}.`, 400);
  }

  await pool.query("UPDATE orders SET status = 'Cancelled' WHERE id = ?", [order.id]);
  return success(res, null, 'Order cancelled.');
});

module.exports = { 
  createOrder, 
  getMyOrders, 
  trackOrder, 
  cancelOrder, 
  toOrderJson 
};