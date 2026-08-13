const { error } = require('../utils/apiResponse');

/**
 * Must be used AFTER requireAuth. Blocks non-admin users.
 * Used for admin panel routes (product/category/order management).
 */
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.is_admin) {
    return error(res, 'Admin access required.', 403);
  }
  next();
}

module.exports = { requireAdmin };