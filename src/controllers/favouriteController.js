const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { toProductJson } = require('./productController');

/** GET /api/favourites - Get user's favourites */
const getFavourites = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT p.*, c.name AS category_name
     FROM favourites f
     JOIN products p ON p.id = f.product_id
     LEFT JOIN categories c ON c.id = p.category_id
     WHERE f.user_id = ?
     ORDER BY f.created_at DESC`,
    [req.user.id]
  );
  return success(res, rows.map(toProductJson));
});

/** POST /api/favourites - Add favourite */
const addFavourite = asyncHandler(async (req, res) => {
  const { product_id } = req.body;
  if (!product_id) return error(res, 'product_id is required.', 400);

  const [productRows] = await pool.query('SELECT id FROM products WHERE id = ?', [product_id]);
  if (productRows.length === 0) return error(res, 'Product not found.', 404);

  await pool.query(
    'INSERT IGNORE INTO favourites (user_id, product_id) VALUES (?, ?)',
    [req.user.id, product_id]
  );
  return success(res, null, 'Added to favourites.', 201);
});

/** DELETE /api/favourites/:productId - Remove favourite */
const removeFavourite = asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM favourites WHERE user_id = ? AND product_id = ?', [
    req.user.id, req.params.productId,
  ]);
  return success(res, null, 'Removed from favourites.');
});

module.exports = { getFavourites, addFavourite, removeFavourite };