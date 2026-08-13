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
    
    // 🔍 DEBUG: Print all environment variables
    console.log('🔍 Environment Variables:');
    console.log('   DB_HOST:', process.env.DB_HOST || 'NOT SET');
    console.log('   MYSQLHOST:', process.env.MYSQLHOST || 'NOT SET');
    console.log('   DB_USER:', process.env.DB_USER || 'NOT SET');
    console.log('   MYSQLUSER:', process.env.MYSQLUSER || 'NOT SET');
    console.log('   DB_PASSWORD:', process.env.DB_PASSWORD ? '***SET***' : 'NOT SET');
    console.log('   MYSQLPASSWORD:', process.env.MYSQLPASSWORD ? '***SET***' : 'NOT SET');
    console.log('   DB_NAME:', process.env.DB_NAME || 'NOT SET');
    console.log('   MYSQLDATABASE:', process.env.MYSQLDATABASE || 'NOT SET');
    
    // Determine which host to use
    const host = process.env.DB_HOST || process.env.MYSQLHOST || 'localhost';
    const port = process.env.DB_PORT || process.env.MYSQLPORT || 3306;
    const user = process.env.DB_USER || process.env.MYSQLUSER || 'root';
    const password = process.env.DB_PASSWORD || process.env.MYSQLPASSWORD || '';
    const database = process.env.DB_NAME || process.env.MYSQLDATABASE || 'ktex_db';
    
    console.log('📡 Connection Config:');
    console.log(`   Host: ${host}`);
    console.log(`   Port: ${port}`);
    console.log(`   User: ${user}`);
    console.log(`   Database: ${database}`);
    
    pool = mysql.createPool({
      host: host,
      port: Number(port),
      user: user,
      password: password,
      database: database,
      waitForConnections: true,
      connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 3),
      queueLimit: 0,
      dateStrings: true,
      enableKeepAlive: true,
      connectTimeout: 30000,
      // For Railway internal connection
      ssl: process.env.MYSQLHOST ? false : undefined,
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
    console.error('   Current values:');
    console.error(`   DB_HOST: ${process.env.DB_HOST || 'NOT SET'}`);
    console.error(`   MYSQLHOST: ${process.env.MYSQLHOST || 'NOT SET'}`);
    console.error(`   DB_USER: ${process.env.DB_USER || 'NOT SET'}`);
    console.error(`   MYSQLUSER: ${process.env.MYSQLUSER || 'NOT SET'}`);
    console.error(`   DB_PASSWORD: ${process.env.DB_PASSWORD ? 'SET' : 'NOT SET'}`);
    console.error(`   MYSQLPASSWORD: ${process.env.MYSQLPASSWORD ? 'SET' : 'NOT SET'}`);
    console.error(`   DB_NAME: ${process.env.DB_NAME || 'NOT SET'}`);
    console.error(`   MYSQLDATABASE: ${process.env.MYSQLDATABASE || 'NOT SET'}`);
  }
})();

module.exports = poolInstance;
