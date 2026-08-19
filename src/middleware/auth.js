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
    // `users.id` is a VARCHAR(128) PRIMARY KEY with NO default and NO
    // auto-increment (confirmed via SHOW CREATE TABLE), so it MUST be
    // supplied explicitly on insert or MySQL rejects the row entirely
    // (ER_NO_DEFAULT_FOR_FIELD). The Firebase uid is already unique and a
    // string, so we simply reuse it as the primary key -- no extra ID
    // generation needed, and id/firebase_uid stay in sync by construction.
    await pool.query(
      `INSERT INTO users
        (id, firebase_uid, name, email, phone, provider, profile_image, is_email_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        uid, uid, name || (email ? email.split('@')[0] : 'KTEX User'),
        email || `${uid}@ktex.local`, phone_number || null,
        provider, picture || null, decoded.email_verified ? 1 : 0,
      ]
    );
    [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [uid]);
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

    let user;
    try {
      user = await resolveAdminUser(token);
      if (!user) user = await resolveFirebaseUser(token);
    } catch (resolveErr) {
      // Genuine failures to verify the token (bad/expired Firebase token,
      // wrong project, etc.) throw from inside admin.auth().verifyIdToken()
      // and SHOULD map to 401. Anything else (DB/schema errors like an
      // unknown column, connection drops, etc.) is a server bug, not an
      // auth problem -- surfacing those as "please log in again" hides
      // real bugs behind a fake session error, so we log the real message
      // and return 500 instead.
      const isTokenError = resolveErr.code && String(resolveErr.code).startsWith('auth/');
      console.error('requireAuth resolve error:', resolveErr.code || '', resolveErr.message);
      if (isTokenError) {
        return error(res, 'Invalid or expired session. Please log in again.', 401);
      }
      return error(res, 'Server error while verifying your session. Please try again shortly.', 500);
    }

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
    // Log it even though we don't block the request -- previously this was
    // swallowed completely, so a broken resolveFirebaseUser (e.g. schema
    // mismatch) meant guest/logged-in orders silently lost their user_id
    // with zero trace in the logs.
    console.error('optionalAuth resolve error:', err.code || '', err.message);
    next();
  }
}

module.exports = { requireAuth, optionalAuth };
