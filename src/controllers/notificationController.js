const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * POST /api/notifications/token - body: { token }
 * Registers an FCM token against the currently authenticated user (JWT).
 * Replaces the old Firestore-by-firebase_uid approach, which silently
 * never worked for email/password customers (they have no Firebase Auth
 * session, so FirebaseAuth.instance.currentUser was always null client-side).
 */
const registerToken = asyncHandler(async (req, res) => {
  const { token } = req.body;
  if (!token) return error(res, 'token is required.', 400);

  const [rows] = await pool.query('SELECT fcm_tokens FROM users WHERE id = ? LIMIT 1', [req.user.id]);
  if (rows.length === 0) return error(res, 'User not found.', 404);

  let tokens = [];
  try {
    tokens = rows[0].fcm_tokens ? JSON.parse(rows[0].fcm_tokens) : [];
    if (!Array.isArray(tokens)) tokens = [];
  } catch (_) {
    tokens = [];
  }

  if (!tokens.includes(token)) {
    tokens.push(token);
    await pool.query('UPDATE users SET fcm_tokens = ? WHERE id = ?', [JSON.stringify(tokens), req.user.id]);
  }

  return success(res, null, 'Token registered.');
});

/**
 * DELETE /api/notifications/token - body: { token }
 * Removes a single token (e.g. on logout) so a shared/reset device
 * doesn't keep receiving another user's pushes.
 */
const removeToken = asyncHandler(async (req, res) => {
  const { token } = req.body;
  if (!token) return error(res, 'token is required.', 400);

  const [rows] = await pool.query('SELECT fcm_tokens FROM users WHERE id = ? LIMIT 1', [req.user.id]);
  if (rows.length === 0) return error(res, 'User not found.', 404);

  let tokens = [];
  try {
    tokens = rows[0].fcm_tokens ? JSON.parse(rows[0].fcm_tokens) : [];
    if (!Array.isArray(tokens)) tokens = [];
  } catch (_) {
    tokens = [];
  }

  tokens = tokens.filter((t) => t !== token);
  await pool.query('UPDATE users SET fcm_tokens = ? WHERE id = ?', [JSON.stringify(tokens), req.user.id]);

  return success(res, null, 'Token removed.');
});

module.exports = { registerToken, removeToken };
