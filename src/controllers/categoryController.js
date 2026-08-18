const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

const FIXED_MAIN_CATEGORIES = ['Men', 'Women', 'Kids'];

/** Ensures Men/Women/Kids exist as top-level categories. Cheap no-op once seeded. */
async function ensureFixedCategories() {
  const [existing] = await pool.query(
    'SELECT name FROM categories WHERE parent_id IS NULL AND name IN (?, ?, ?)',
    FIXED_MAIN_CATEGORIES
  );
  const existingNames = existing.map((r) => r.name);
  const missing = FIXED_MAIN_CATEGORIES.filter((n) => !existingNames.includes(n));
  if (missing.length === 0) return;

  for (const name of missing) {
    await pool.query('INSERT INTO categories (name, image_url) VALUES (?, NULL)', [name]);
  }
}

/** GET /api/categories - Public - Returns all categories, or subcategories of ?parent=Men */
const getCategories = asyncHandler(async (req, res) => {
  await ensureFixedCategories();
  const { parent } = req.query;

  let sql = `
    SELECT c.*, p.name AS parent_name
    FROM categories c
    LEFT JOIN categories p ON p.id = c.parent_id
  `;
  const values = [];

  if (parent) {
    sql += ' WHERE p.name = ?';
    values.push(parent);
  }

  sql += ' ORDER BY (c.parent_id IS NULL) DESC, c.name ASC';

  const [rows] = await pool.query(sql, values);
  return success(res, rows);
});

/** GET /api/categories/:id - Public */
const getCategoryById = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT c.*, p.name AS parent_name FROM categories c
     LEFT JOIN categories p ON p.id = c.parent_id
     WHERE c.id = ?`,
    [req.params.id]
  );
  if (rows.length === 0) return error(res, 'Category not found.', 404);
  return success(res, rows[0]);
});

/** POST /api/categories - Admin only */
const createCategory = asyncHandler(async (req, res) => {
  const { name, image_url, parent_id } = req.body;
  if (!name) return error(res, 'name is required.', 400);

  const [result] = await pool.query(
    'INSERT INTO categories (name, image_url, parent_id) VALUES (?, ?, ?)',
    [name, image_url || null, parent_id || null]
  );
  const [rows] = await pool.query(
    `SELECT c.*, p.name AS parent_name FROM categories c
     LEFT JOIN categories p ON p.id = c.parent_id
     WHERE c.id = ?`,
    [result.insertId]
  );
  return success(res, rows[0], 'Category created.', 201);
});

/** PUT /api/categories/:id - Admin only */
const updateCategory = asyncHandler(async (req, res) => {
  const { name, image_url, parent_id } = req.body;
  const fields = [];
  const values = [];

  if (name !== undefined) { fields.push('name = ?'); values.push(name); }
  if (image_url !== undefined) { fields.push('image_url = ?'); values.push(image_url); }
  if (parent_id !== undefined) { fields.push('parent_id = ?'); values.push(parent_id || null); }
  if (fields.length === 0) return error(res, 'Nothing to update.', 400);

  values.push(req.params.id);
  const [result] = await pool.query(`UPDATE categories SET ${fields.join(', ')} WHERE id = ?`, values);
  if (result.affectedRows === 0) return error(res, 'Category not found.', 404);

  const [rows] = await pool.query(
    `SELECT c.*, p.name AS parent_name FROM categories c
     LEFT JOIN categories p ON p.id = c.parent_id
     WHERE c.id = ?`,
    [req.params.id]
  );
  return success(res, rows[0], 'Category updated.');
});

/** DELETE /api/categories/:id - Admin only */
const deleteCategory = asyncHandler(async (req, res) => {
  // Check if category has products
  const [products] = await pool.query('SELECT COUNT(*) as count FROM products WHERE category_id = ?', [req.params.id]);
  if (products[0].count > 0) {
    return error(res, 'Cannot delete category with existing products. Move or delete products first.', 400);
  }

  const [result] = await pool.query('DELETE FROM categories WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'Category not found.', 404);
  return success(res, null, 'Category deleted.');
});

module.exports = { getCategories, getCategoryById, createCategory, updateCategory, deleteCategory };
