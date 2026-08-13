const jwt = require('jsonwebtoken');
const admin = require('../config/firebase');
const pool = require('../config/db');
const { error } = require('../utils/apiResponse');

/**
 * Two kinds of bearer token can show up in Authorization: Bearer <token>:
 *  1. Our own JWT, issued by POST /api/auth/login (admin panel, email +
 *     password checked against users.password_hash).
 *  2. A Firebase ID token, issued by Firebase on the Flutter app (Google +
 *     email/password) -- unchanged from before.
 * We try our own JWT first (cheap, local, no network call); if that fails
 * to verify we fall back to Firebase. This means one requireAuth works for
 * both the admin panel and the shopper app without either knowing about
 * the other's login method.
 */

/* Our own admin token -- returns the users row, or null if not our JWT. */
async function resolveAdminUser(token) {
  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (e) {
    return null; // not one of ours (or expired/invalid) -- let Firebase have a try
  }
  if (decoded.type !== 'admin') return null;

  const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [decoded.id]);
  return rows[0] || null;
}

/**
 * Verifies the Firebase ID token the Flutter app sends after Google or
 * email/password login (same token for both -- Firebase issues it either way).
 * On first sight of a firebase_uid, auto-provisions a row in our local
 * `users` table so orders/cart/favourites/admin-flag can reference it.
 */
async function resolveFirebaseUser(idToken) {
  const decoded = await admin.auth().verifyIdToken(idToken);
  const { uid, email, name, phone_number, picture, firebase } = decoded;
  const provider = firebase?.sign_in_provider === 'google.com' ? 'google' : 'email';

  let [rows] = await pool.query('SELECT * FROM users WHERE firebase_uid = ? LIMIT 1', [uid]);

  if (rows.length === 0) {
    const [result] = await pool.query(
      `INSERT INTO users
        (firebase_uid, name, email, phone, provider, profile_image, is_email_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        uid, name || (email ? email.split('@')[0] : 'KTEX User'), email || null, phone_number || null,
        provider, picture || null, decoded.email_verified ? 1 : 0,
      ]
    );
    [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
  }

  return rows[0];
}

function toReqUser(user) {
  return {
    id: user.id,
    firebase_uid: user.firebase_uid,
    name: user.name,
    email: user.email,
    phone: user.phone,
    is_admin: !!user.is_admin,
  };
}

/* Requires header: Authorization: Bearer <our JWT OR a Firebase ID token> */
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return error(res, 'Authentication required. Please log in.', 401);
    }

    let user = await resolveAdminUser(token);
    if (!user) user = await resolveFirebaseUser(token);

    if (!user) {
      return error(res, 'Invalid or expired session. Please log in again.', 401);
    }
    if (!user.is_active) {
      return error(res, 'This account has been deactivated. Contact support.', 403);
    }

    req.user = toReqUser(user);
    next();
  } catch (err) {
    console.error('Auth error:', err.message);
    return error(res, 'Invalid or expired session. Please log in again.', 401);
  }
}

/* Attaches req.user if a valid token is present, but never blocks the request. */
async function optionalAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return next();

    let user = await resolveAdminUser(token);
    if (!user) user = await resolveFirebaseUser(token);

    if (user) req.user = toReqUser(user);
    next();
  } catch (err) {
    next();
  }
}

module.exports = { requireAuth, optionalAuth };