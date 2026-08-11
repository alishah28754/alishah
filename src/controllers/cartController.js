const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/* GET /api/cart - protected, returns items in CartItem.fromJson() shape */
const getCart = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT p.id AS product_id, p.name, p.image_url, p.price, ci.quantity
     FROM cart_items ci
     JOIN products p ON p.id = ci.product_id
     WHERE ci.user_id = ?
     ORDER BY ci.created_at DESC`,
    [req.user.id]
  );
  const items = rows.map((r) => ({
    product_id: String(r.product_id),
    name: r.name,
    image_url: r.image_url,
    price: r.price,
    quantity: r.quantity,
  }));
  return success(res, items);
});

/* POST /api/cart - protected, body: { product_id, quantity? } - add or increment */
const addToCart = asyncHandler(async (req, res) => {
  const { product_id, quantity } = req.body;
  if (!product_id) return error(res, 'product_id is required.', 400);

  const [productRows] = await pool.query('SELECT id FROM products WHERE id = ?', [product_id]);
  if (productRows.length === 0) return error(res, 'Product not found.', 404);

  await pool.query(
    `INSERT INTO cart_items (user_id, product_id, quantity)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)`,
    [req.user.id, product_id, quantity || 1]
  );

  return success(res, null, 'Added to cart.', 201);
});

/* PUT /api/cart/:productId - protected, body: { quantity } - set exact quantity */
const updateCartItem = asyncHandler(async (req, res) => {
  const { quantity } = req.body;
  if (quantity === undefined) return error(res, 'quantity is required.', 400);

  if (Number(quantity) <= 0) {
    await pool.query('DELETE FROM cart_items WHERE user_id = ? AND product_id = ?', [
      req.user.id, req.params.productId,
    ]);
    return success(res, null, 'Item removed from cart.');
  }

  const [result] = await pool.query(
    'UPDATE cart_items SET quantity = ? WHERE user_id = ? AND product_id = ?',
    [quantity, req.user.id, req.params.productId]
  );
  if (result.affectedRows === 0) return error(res, 'Item not found in cart.', 404);
  return success(res, null, 'Cart updated.');
});

/* DELETE /api/cart/:productId - protected */
const removeFromCart = asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM cart_items WHERE user_id = ? AND product_id = ?', [
    req.user.id, req.params.productId,
  ]);
  return success(res, null, 'Item removed from cart.');
});

/* DELETE /api/cart - protected, clears the whole cart */
const clearCart = asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);
  return success(res, null, 'Cart cleared.');
});

module.exports = { getCart, addToCart, updateCartItem, removeFromCart, clearCart };
