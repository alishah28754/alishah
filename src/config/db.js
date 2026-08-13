const mysql = require('mysql2/promise');

/**
 * Database connection pool with singleton pattern for serverless.
 * Uses a single pool instance across all function invocations to
 * prevent connection limit exhaustion on Vercel/Serverless.
 *
 * Supports BOTH naming conventions so it works unmodified on either
 * Railway (which auto-injects MYSQLHOST/MYSQLUSER/MYSQLPASSWORD/
 * MYSQLDATABASE/MYSQLPORT when you attach its MySQL plugin) or any
 * other host using the DB_HOST/DB_USER/DB_PASSWORD/DB_NAME/DB_PORT
 * convention (Hostinger, Vercel + external MySQL, local .env, etc).
 * DB_* takes priority if both happen to be set.
 */
let pool = null;

function getPool() {
  if (!pool) {
    console.log('🔌 Creating MySQL connection pool...');
    pool = mysql.createPool({
      host: process.env.DB_HOST || process.env.MYSQLHOST || 'localhost',
      port: process.env.DB_PORT || process.env.MYSQLPORT || 3306,
      user: process.env.DB_USER || process.env.MYSQLUSER || 'root',
      password: process.env.DB_PASSWORD || process.env.MYSQLPASSWORD || '',
      database: process.env.DB_NAME || process.env.MYSQLDATABASE || 'ktex_db',
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
    const dbName = process.env.DB_NAME || process.env.MYSQLDATABASE || 'ktex_db';
    console.log(`✅ MySQL connected successfully: ${dbName}`);
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    console.error('   Check your DB_* or MYSQL* environment variables.');
  }
})();

module.exports = poolInstance;
