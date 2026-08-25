const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { error } = require('../utils/apiResponse');

/**
 * Only one kind of bearer token now: our own JWT.
 * type:'admin' -> issued by adminLogin
 * type:'customer' -> issued by customerLogin / verifyOtp
 * Both resolve to a row in `users` and are treated identically by
 * downstream routes (req.user), except is_admin gates admin-only routes.
 */
async function resolveUser(token) {
  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (e) {
    return null; // invalid or expired
  }
  if (decoded.type !== 'admin' && decoded.type !== 'customer') return null;

  const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [decoded.id]);
  return rows[0] || null;
}

function toReqUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    is_admin: !!user.is_admin,
  };
}

/* Requires header: Authorization: Bearer <our JWT> */
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return error(res, 'Authentication required. Please log in.', 401);
    }

    const user = await resolveUser(token);

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

    const user = await resolveUser(token);
    if (user) req.user = toReqUser(user);
    next();
  } catch (err) {
    console.error('optionalAuth resolve error:', err.message);
    next();
  }
}

module.exports = { requireAuth, optionalAuth };
