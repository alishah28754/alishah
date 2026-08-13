const { error } = require('../utils/apiResponse');

function errorHandler(err, req, res, next) {
  console.error('❌', err.message);
  console.error('   Stack:', err.stack);

  // Map database errors to user-friendly messages
  const errorMap = {
    'ER_DUP_ENTRY': 'This record already exists (duplicate entry).',
    'ER_NO_REFERENCED_ROW_2': 'Related record not found (invalid reference).',
    'ER_NO_REFERENCED_ROW': 'Related record not found (invalid reference).',
    'ER_ROW_IS_REFERENCED_2': 'Cannot delete: this record is used elsewhere.',
    'ER_ROW_IS_REFERENCED': 'Cannot delete: this record is used elsewhere.',
  };

  const message = errorMap[err.code] || err.message || 'Internal server error';
  const statusCode = err.statusCode || (err.code?.startsWith('ER_') ? 400 : 500);

  return error(res, message, statusCode);
}

function notFound(req, res) {
  return error(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

module.exports = { errorHandler, notFound };