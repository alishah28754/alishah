const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * NOTE on auth:
 * - The Flutter app (shoppers) still authenticates with Firebase, exactly
 *   as before -- see middleware/auth.js.
 * - The KTEX ADMIN PANEL logs in separately, with plain email + password
 *   checked against this table's password_hash column (set via
 *   database/set-admin-password.js). adminLogin below issues our own JWT
 *   for that session; requireAuth accepts either kind of token.
 */

/* POST /api/auth/admin-login - public. Email + password against MySQL. */
const adminLogin = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return error(res, 'Email and password are required.', 400);
  }

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  // Same generic message whether the email doesn't exist or the password is
  // wrong -- don't reveal which one it was.
  if (!user || !user.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
    return error(res, 'Invalid email or password.', 401);
  }

  if (!user.is_admin) {
    return error(res, 'This account does not have admin access.', 403);
  }

  const token = jwt.sign(
    { id: user.id, type: 'admin' },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return success(res, {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      is_admin: !!user.is_admin,
    },
  }, 'Logged in.');
});

/* GET /api/auth/me - protected */
const getMe = asyncHandler(async (req, res) => {
  return success(res, req.user);
});

/* PUT /api/auth/profile - protected, updates the LOCAL copy (name/phone only;
   email/password changes must happen through Firebase on the client, or via
   database/set-admin-password.js for admin accounts) */
const updateProfile = asyncHandler(async (req, res) => {
  const { name, phone } = req.body;
  const fields = [];
  const values = [];

  if (name) { fields.push('name = ?'); values.push(name); }
  if (phone !== undefined) { fields.push('phone = ?'); values.push(phone); }

  if (fields.length === 0) {
    return error(res, 'Nothing to update.', 400);
  }

  values.push(req.user.id);
  await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);

  const [rows] = await pool.query(
    'SELECT id, firebase_uid, name, email, phone, is_admin FROM users WHERE id = ?',
    [req.user.id]
  );
  return success(res, rows[0], 'Profile updated.');
});

module.exports = { adminLogin, getMe, updateProfile };
