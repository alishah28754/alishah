// src/controllers/productController.js
const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { sendPushToTopic } = require('../utils/pushNotifications');

function generateProductId() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 6);
  return `prod-${timestamp}-${random}`;
}

function parseColorsField(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
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
    subcategory: row.subcategory_name || null,
    subcategory_id: row.subcategory_id ?? null,
    description: row.description || '',
    stock: row.stock ?? 0,
    colors: parseColorsField(row.colors),
    is_flash_sale: !!row.is_flash_sale,
    is_new_arrival: !!row.is_new_arrival,
    is_best_seller: !!row.is_best_seller,
    is_collection: !!row.is_collection,
    is_for_you: !!row.is_for_you,
    metadata: row.metadata ? (typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata) : null,
  };
}

const BASE_SELECT = `
  SELECT p.*, c.name AS category_name, s.name AS subcategory_name
  FROM products p
  LEFT JOIN categories c ON c.id = p.category_id
  LEFT JOIN categories s ON s.id = p.subcategory_id
`;

const getProducts = asyncHandler(async (req, res) => {
  const { 
    category, 
    subcategory, 
    search, 
    is_premium, 
    is_new_arrival,
    is_best_seller,
    is_flash_sale,
    is_for_you,
    page = 1, 
    limit = 100 
  } = req.query;

  const where = [];
  const values = [];

  // FIX: Handle category by name properly
  if (category) {
    const [catRows] = await pool.query('SELECT id FROM categories WHERE name = ?', [category]);
    if (catRows.length > 0) {
      where.push('p.category_id = ?');
      values.push(catRows[0].id);
    } else {
      // If category doesn't exist, return empty
      return success(res, { items: [], total: 0 });
    }
  }
  
  if (subcategory) { 
    where.push('s.name = ?'); 
    values.push(subcategory); 
  }
  
  if (search) { 
    where.push('p.name LIKE ?'); 
    values.push(`%${search}%`); 
  }
  
  if (is_premium !== undefined) { 
    where.push('p.is_premium = ?'); 
    values.push(is_premium === 'true' ? 1 : 0); 
  }
  if (is_new_arrival !== undefined) { 
    where.push('p.is_new_arrival = ?'); 
    values.push(is_new_arrival === 'true' ? 1 : 0); 
  }
  if (is_best_seller !== undefined) { 
    where.push('p.is_best_seller = ?'); 
    values.push(is_best_seller === 'true' ? 1 : 0); 
  }
  if (is_flash_sale !== undefined) { 
    where.push('p.is_flash_sale = ?'); 
    values.push(is_flash_sale === 'true' ? 1 : 0); 
  }
  if (is_for_you !== undefined) { 
    where.push('p.is_for_you = ?'); 
    values.push(is_for_you === 'true' ? 1 : 0); 
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (Math.max(1, Number(page)) - 1) * Number(limit);

  const [rows] = await pool.query(
    `${BASE_SELECT} ${whereSql} ORDER BY p.created_at DESC LIMIT ? OFFSET ?`,
    [...values, Number(limit), offset]
  );
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM products p LEFT JOIN categories c ON c.id = p.category_id LEFT JOIN categories s ON s.id = p.subcategory_id ${whereSql}`,
    values
  );

  return success(res, {
    items: rows.map(toProductJson),
    page: Number(page),
    limit: Number(limit),
    total: countRows[0].total,
  });
});

const getFlashSale = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_flash_sale = 1 ORDER BY p.created_at DESC LIMIT 100`);
  return success(res, rows.map(toProductJson));
});

const getNewArrivals = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_new_arrival = 1 ORDER BY p.created_at DESC LIMIT 100`);
  return success(res, rows.map(toProductJson));
});

const getForYou = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_for_you = 1 ORDER BY p.created_at DESC LIMIT 100`);
  return success(res, rows.map(toProductJson));
});

const getBestSellers = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.is_best_seller = 1 ORDER BY p.created_at DESC LIMIT 100`);
  return success(res, rows.map(toProductJson));
});

const getProductById = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [req.params.id]);
  if (rows.length === 0) return error(res, 'Product not found.', 404);
  return success(res, toProductJson(rows[0]));
});

const createProduct = asyncHandler(async (req, res) => {
  const {
    name, image_url, price, original_price, discount_percent, sold_label,
    is_premium, category, subcategory_id, description, stock, colors,
    is_flash_sale, is_new_arrival, is_best_seller, is_collection, is_for_you, metadata,
  } = req.body;

  if (!name || !image_url || price === undefined) {
    return error(res, 'name, image_url and price are required.', 400);
  }

  const id = generateProductId();

  // FIX: Convert category name to ID properly
  let category_id = null;
  if (category) {
    const [catRows] = await pool.query('SELECT id FROM categories WHERE name = ?', [category]);
    if (catRows.length > 0) {
      category_id = catRows[0].id;
    }
  }

  const [result] = await pool.query(
    `INSERT INTO products
      (id, name, image_url, price, original_price, discount_percent, sold_label,
       is_premium, category_id, subcategory_id, description, stock, colors,
       is_flash_sale, is_new_arrival, is_best_seller, is_collection, is_for_you, metadata)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id, 
      name, 
      image_url, 
      price, 
      original_price || null, 
      discount_percent || null, 
      sold_label || null,
      is_premium ? 1 : 0, 
      category_id,
      subcategory_id || null, 
      description || null, 
      stock || 0,
      colors ? JSON.stringify(colors) : null,
      is_flash_sale ? 1 : 0, 
      is_new_arrival ? 1 : 0, 
      is_best_seller ? 1 : 0, 
      is_collection ? 1 : 0, 
      is_for_you ? 1 : 0,
      metadata ? JSON.stringify(metadata) : null,
    ]
  );

  const [rows] = await pool.query(`${BASE_SELECT} WHERE p.id = ?`, [id]);
  const product = toProductJson(rows[0]);

  // Fire-and-forget: announce the new product to everyone subscribed to the
  // 'new_products' topic. Never awaited into the response — a push failure
  // must not delay or fail product creation in the admin panel.
  sendPushToTopic('new_products', {
    title: 'New arrival at KTEX!',
    body: `${product.name} just landed — check it out.`,
    data: { productId: product.id, type: 'new_product' },
  });

  return success(res, product, 'Product created.', 201);
});

const updateProduct = asyncHandler(async (req, res) => {
  const {
    name, image_url, price, original_price, discount_percent, sold_label,
    is_premium, category, subcategory_id, description, stock,
    is_flash_sale, is_new_arrival, is_best_seller, is_collection, is_for_you, metadata,
  } = req.body;

  const fields = [];
  const values = [];

  // FIX: Handle category properly - convert name to ID
  if (category !== undefined) {
    let category_id = null;
    if (category) {
      const [catRows] = await pool.query('SELECT id FROM categories WHERE name = ?', [category]);
      if (catRows.length > 0) {
        category_id = catRows[0].id;
      }
    }
    fields.push('category_id = ?');
    values.push(category_id);
  }

  // FIX: Handle all boolean flags properly - they should update even when false
  const booleanFields = [
    'is_premium', 
    'is_flash_sale', 
    'is_new_arrival', 
    'is_best_seller', 
    'is_collection', 
    'is_for_you'
  ];

  for (const key of booleanFields) {
    if (req.body[key] !== undefined) {
      fields.push(`${key} = ?`);
      // Convert to 1 or 0 explicitly
      values.push(req.body[key] ? 1 : 0);
    }
  }

  // Handle other fields
  const otherFields = [
    'name', 'image_url', 'price', 'original_price', 'discount_percent', 
    'sold_label', 'subcategory_id', 'description', 'stock', 'colors', 'metadata'
  ];

  for (const key of otherFields) {
    if (req.body[key] !== undefined) {
      fields.push(`${key} = ?`);
      let val = req.body[key];
      if (key === 'metadata') val = val ? JSON.stringify(val) : null;
      if (key === 'colors') val = val ? JSON.stringify(val) : null;
      if (key === 'subcategory_id') val = val || null;
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

const deleteProduct = asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'Product not found.', 404);
  return success(res, null, 'Product deleted.');
});

module.exports = {
  getProducts,
  getFlashSale,
  getNewArrivals,
  getForYou,
  getBestSellers,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  toProductJson,
};
