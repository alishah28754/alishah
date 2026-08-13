/**
 * Consistent JSON response shape used across every route so the
 * Flutter app (and the admin panel) can rely on one contract:
 *   { success: true,  data: ... , message?: ... }
 *   { success: false, message: ..., errors?: [...] }
 */
function success(res, data = null, message = 'OK', statusCode = 200) {
  return res.status(statusCode).json({ success: true, message, data });
}

function error(res, message = 'Something went wrong', statusCode = 500, errors = null) {
  return res.status(statusCode).json({ success: false, message, errors });
}

module.exports = { success, error };