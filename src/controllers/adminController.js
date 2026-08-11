const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { toOrderJson } = require('./orderController');

/* GET /api/admin/stats - dashboard summary for the admin panel */
const getDashboardStats = asyncHandler(async (req, res) => {
  const [[{ totalUsers }]] = await pool.query('SELECT COUNT(*) AS totalUsers FROM users WHERE is_admin = 0');
  const [[{ totalProducts }]] = await pool.query('SELECT COUNT(*) AS totalProducts FROM products');
  const [[{ totalOrders }]] = await pool.query('SELECT COUNT(*) AS totalOrders FROM orders');
  const [[{ totalRevenue }]] = await pool.query(
    "SELECT COALESCE(SUM(total),0) AS totalRevenue FROM orders WHERE status != 'Cancelled'"
  );
  const [[{ pendingOrders }]] = await pool.query(
    "SELECT COUNT(*) AS pendingOrders FROM orders WHERE status = 'Processing'"
  );

  // last 7 days sales trend (for fl_chart in ktex-admin)
  const [salesTrend] = await pool.query(
    `SELECT DATE(created_at) AS date, COALESCE(SUM(total),0) AS revenue, COUNT(*) AS orders
     FROM orders
     WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND status != 'Cancelled'
     GROUP BY DATE(created_at)
     ORDER BY date ASC`
  );

  return success(res, {
    totalUsers, totalProducts, totalOrders, totalRevenue, pendingOrders, salesTrend,
  });
});

/* GET /api/admin/orders - all orders, supports ?status= */
const getAllOrders = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const where = status ? 'WHERE status = ?' : '';
  const values = status ? [status] : [];

  const [orders] = await pool.query(
    `SELECT * FROM orders ${where} ORDER BY created_at DESC`,
    values
  );

  const results = [];
  for (const order of orders) {
    const [itemRows] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
    results.push({
      ...toOrderJson(order, itemRows),
      order_number: order.order_number,
      customer_name: order.customer_name,
      email: order.email,
      phone: order.phone,
      address: order.address,
      city: order.city,
    });
  }
  return success(res, results);
});

/* PUT /api/admin/orders/:orderNumber/status - body: { status } */
const updateOrderStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['Processing', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
  if (!validStatuses.includes(status)) {
    return error(res, `status must be one of: ${validStatuses.join(', ')}`, 400);
  }

  const [result] = await pool.query(
    'UPDATE orders SET status = ? WHERE order_number = ?',
    [status, req.params.orderNumber]
  );
  if (result.affectedRows === 0) return error(res, 'Order not found.', 404);

  return success(res, null, `Order status updated to ${status}.`);
});

/* GET /api/admin/users - list all customers */
const getAllUsers = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT id, name, email, phone, is_admin, created_at FROM users ORDER BY created_at DESC'
  );
  return success(res, rows);
});

/* DELETE /api/admin/users/:id */
const deleteUser = asyncHandler(async (req, res) => {
  if (Number(req.params.id) === req.user.id) {
    return error(res, 'You cannot delete your own admin account.', 400);
  }
  const [result] = await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'User not found.', 404);
  return success(res, null, 'User deleted.');
});

/* PUT /api/admin/users/:id/toggle-admin - promote/demote a user */
const toggleAdmin = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT is_admin FROM users WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return error(res, 'User not found.', 404);

  const newValue = rows[0].is_admin ? 0 : 1;
  await pool.query('UPDATE users SET is_admin = ? WHERE id = ?', [newValue, req.params.id]);
  return success(res, { is_admin: !!newValue }, 'User role updated.');
});

module.exports = {
  getDashboardStats, getAllOrders, updateOrderStatus, getAllUsers, deleteUser, toggleAdmin,
};
