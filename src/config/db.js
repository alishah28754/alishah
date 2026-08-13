const mysql = require('mysql2/promise');

/**
 * Database connection pool with singleton pattern for serverless.
 * Uses a single pool instance across all function invocations to
 * prevent connection limit exhaustion on Vercel/Serverless.
 */
let pool = null;

function getPool() {
  if (!pool) {
    console.log('🔌 Creating MySQL connection pool...');
    pool = mysql.createPool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'ktex_db',
      waitForConnections: true,
      connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 3),
      queueLimit: 0,
      dateStrings: true,
      enableKeepAlive: true,
    });
  }
  return pool;
}

// Export the singleton pool
const poolInstance = getPool();

// Test connection on startup (non-blocking)
(async () => {
  try {
    const conn = await poolInstance.getConnection();
    console.log('✅ MySQL connected successfully');
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    console.error('   Check your .env DB_* values');
  }
})();

module.exports = poolInstance;