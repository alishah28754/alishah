const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/* GET /api/categories - public */
const getCategories = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM categories ORDER BY name ASC');
  return success(res, rows);
});

/* GET /api/categories/:id - public */
const getCategoryById = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return error(res, 'Category not found.', 404);
  return success(res, rows[0]);
});

/* POST /api/categories - admin only (used by web admin panel) */
const createCategory = asyncHandler(async (req, res) => {
  const { name, image_url } = req.body;
  if (!name) return error(res, 'name is required.', 400);

  const [result] = await pool.query(
    'INSERT INTO categories (name, image_url) VALUES (?, ?)',
    [name, image_url || null]
  );
  const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [result.insertId]);
  return success(res, rows[0], 'Category created.', 201);
});

/* PUT /api/categories/:id - admin only */
const updateCategory = asyncHandler(async (req, res) => {
  const { name, image_url } = req.body;
  const fields = [];
  const values = [];

  if (name !== undefined) { fields.push('name = ?'); values.push(name); }
  if (image_url !== undefined) { fields.push('image_url = ?'); values.push(image_url); }
  if (fields.length === 0) return error(res, 'Nothing to update.', 400);

  values.push(req.params.id);
  const [result] = await pool.query(`UPDATE categories SET ${fields.join(', ')} WHERE id = ?`, values);
  if (result.affectedRows === 0) return error(res, 'Category not found.', 404);

  const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [req.params.id]);
  return success(res, rows[0], 'Category updated.');
});

/* DELETE /api/categories/:id - admin only */
const deleteCategory = asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM categories WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'Category not found.', 404);
  return success(res, null, 'Category deleted.');
});

module.exports = { getCategories, getCategoryById, createCategory, updateCategory, deleteCategory };
