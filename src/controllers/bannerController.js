const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

function toBannerJson(row) {
  return {
    id: String(row.id),
    title: row.title,
    subtitle: row.subtitle,
    image_url: row.image_url,
    category: row.category,
  };
}

/** GET /api/banners - Public, active banners only */
const getBanners = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT * FROM banners WHERE is_active = 1 ORDER BY sort_order ASC, id ASC'
  );
  return success(res, rows.map(toBannerJson));
});

/** POST /api/banners - Admin only */
const createBanner = asyncHandler(async (req, res) => {
  const { title, subtitle, image_url, category, sort_order } = req.body;
  if (!title || !image_url) return error(res, 'title and image_url are required.', 400);

  const [result] = await pool.query(
    'INSERT INTO banners (title, subtitle, image_url, category, sort_order) VALUES (?, ?, ?, ?, ?)',
    [title, subtitle || null, image_url, category || null, sort_order || 0]
  );
  const [rows] = await pool.query('SELECT * FROM banners WHERE id = ?', [result.insertId]);
  return success(res, toBannerJson(rows[0]), 'Banner created.', 201);
});

/** PUT /api/banners/:id - Admin only */
const updateBanner = asyncHandler(async (req, res) => {
  const allowed = ['title', 'subtitle', 'image_url', 'category', 'sort_order', 'is_active'];
  const fields = [];
  const values = [];

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      fields.push(`${key} = ?`);
      values.push(key === 'is_active' ? (req.body[key] ? 1 : 0) : req.body[key]);
    }
  }
  if (fields.length === 0) return error(res, 'Nothing to update.', 400);

  values.push(req.params.id);
  const [result] = await pool.query(`UPDATE banners SET ${fields.join(', ')} WHERE id = ?`, values);
  if (result.affectedRows === 0) return error(res, 'Banner not found.', 404);

  const [rows] = await pool.query('SELECT * FROM banners WHERE id = ?', [req.params.id]);
  return success(res, toBannerJson(rows[0]), 'Banner updated.');
});

/** DELETE /api/banners/:id - Admin only */
const deleteBanner = asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM banners WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return error(res, 'Banner not found.', 404);
  return success(res, null, 'Banner deleted.');
});

module.exports = { getBanners, createBanner, updateBanner, deleteBanner };