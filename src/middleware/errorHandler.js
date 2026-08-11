const { error } = require('../utils/apiResponse');

/* eslint-disable no-unused-vars */
function errorHandler(err, req, res, next) {
  console.error('❌', err.message);

  if (err.code === 'ER_DUP_ENTRY') {
    return error(res, 'This record already exists (duplicate entry).', 409);
  }
  if (err.code === 'ER_NO_REFERENCED_ROW_2' || err.code === 'ER_NO_REFERENCED_ROW') {
    return error(res, 'Related record not found (invalid reference).', 400);
  }
  if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_ROW_IS_REFERENCED') {
    return error(res, 'Cannot delete: this record is used elsewhere.', 409);
  }
  if (err.name === 'MulterError') {
    return error(res, `Upload error: ${err.message}`, 400);
  }

  return error(res, err.message || 'Internal server error', err.statusCode || 500);
}

function notFound(req, res) {
  return error(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

module.exports = { errorHandler, notFound };
