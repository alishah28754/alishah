const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Generate unique product ID
 * Format: prod-{timestamp}-{random4chars}
 */
function generateProductId() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 6);
  return `prod-${timestamp}-${random}`;
}

function toProductJson(row) {
  return {
    id: String(row.id),
    name: row.name,
    image_url: row.image_url,
    price: row.price,
    original_price: row.original_price,
    discount_percent: row.discount_percent,
    sold_label: row.sold_label,
    is_premium: !!row.is_premium,
    category: row.category_name || null,
    category_id: row.category_id ?? null,
    description: row.description || '',
    stock: row.stock ?? 0,
    is_flash_sale: !!row.is_flash_sale,
    is_new_arrival: !!row.is_new_arrival,
    is_for_you: !!row.is_for_you,
    metadata: row.metadata ? (typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata) : null,
  };
}

const BASE_SELECT = `
  SELECT p.*, c.name AS category_name
  FROM products p
  LEFT JOIN categories c ON c.id = p.category_id
`;

/** GET /api/products - Filtered product list */
const getProducts = asyncHandler(async (req, res) => {
  const { category, search, is_premium, page = 1, limit = 100 } = req.query;

  const where = [];
  const values = [];

  if (category) { where.push('c.name = ?'); values.push(category); }
  if (search) { where.push('p.name LIKE ?'); values.push(`%${search}%`); }
  if (is_premium !== undefined) { where.push('p.is_premium = ?'); values.push(is_premium === 'true' ? 1 : 0); }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (Math.max(1, Number(page)) - 1) * Number(limit);

  const [rows] = await pool.query(
    `${BASE_SELECT} ${whereSql} ORDER BY p.created_at DESC LIMIT ? OFFSET ?`,
    [...values, Number(limit), offset]
  );
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM products p LEFT JOIN categories c ON c.id = p.category_id ${whereSql}`,
    values
  );

  return success(res, {
    items: rows.map(toProductJson),
    page: Number(page),
    limit: Number(limit),
    total: countRows[0].total,
  });
});

/** GET /api/products/flash-sale */
const getFlashSale = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_flash_sale = 1 ORDER BY p.created_at DESC`);
  return success(res, rows.map(toProductJson));
});

/** GET /api/products/new-arrivals */
const getNewArrivals = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_new_arrival = 1 ORDER BY p.created_at DESC`);
  return success(res, rows.map(toProductJson));
});

/** GET /api/products/for-you */
const getForYou = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_for_you = 1 ORDER BY p.created_at DESC`);
  return success(res, rows.map(toProductJson));
});

/** GET /api/products/:id - Single product */
const getProductById = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [req.params.id]);
  if (rows.length === 0) return error(res, 'Product not found.', 404);
  return success(res, toProductJson(rows[0]));
});

/** POST /api/products - Admin only - Creates product with auto-generated ID */
const createProduct = asyncHandler(async (req, res) => {
  const {
    name, image_url, price, original_price, discount_percent, sold_label,
    is_premium, category_id, description, stock,
    is_flash_sale, is_new_arrival, is_for_you, metadata,
  } = req.body;

  if (!name || !image_url || price === undefined) {
    return error(res, 'name, image_url and price are required.', 400);
  }

  // ✅ Auto-generate unique ID
  const id = generateProductId();

  const [result] = await pool.query(
    `INSERT INTO products
      (id, name, image_url, price, original_price, discount_percent, sold_label,
       is_premium, category_id, description, stock, is_flash_sale, is_new_arrival, is_for_you, metadata)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id, name, image_url, price, original_price || null, discount_percent || null, sold_label || null,
      is_premium ? 1 : 0, category_id || null, description || null, stock || 0,
      is_flash_sale ? 1 : 0, is_new_arrival ? 1 : 0, is_for_you ? 1 : 0,
      metadata ? JSON.stringify(metadata) : null,
    ]
  );

  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [id]);
  return success(res, toProductJson(rows[0]), 'Product created.', 201);
});

/** PUT /api/products/:id - Admin only */
const updateProduct = asyncHandler(async (req, res) => {
  const allowed = [
    'name', 'image_url', 'price', 'original_price', 'discount_percent', 'sold_label',
    'is_premium', 'category_id', 'description', 'stock', 'is_flash_sale', 'is_new_arrival', 'is_for_you', 'metadata',
  ];
  const fields = [];
  const values = [];

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      fields.push(`${key} = ?`);
      let val = req.body[key];
      if (['is_premium', 'is_flash_sale', 'is_new_arrival', 'is_for_you'].includes(key)) val = val ? 1 : 0;
      if (key === 'metadata') val = val ? JSON.stringify(val) : null;
      values.push(val);
    }
  }

  if (fields.length === 0) return error(res, 'Nothing to update.', 400);

  values.push(req.params.id);
  const [result] = await pool.query(`UPDATE products SET ${fields.join(', ')} WHERE id = ?`, values);
  if (result.affectedRows === 0) return error(res, 'Product not found.', 404);

  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [req.params.id]);
  return success(res, toProductJson(rows[0]), 'Product updated.');
});

/** DELETE /api/products/:id - Admin only */
const deleteProduct = asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'Product not found.', 404);
  return success(res, null, 'Product deleted.');
});

module.exports = {
  getProducts, getFlashSale, getNewArrivals, getForYou, getProductById,
  createProduct, updateProduct, deleteProduct, toProductJson,
};