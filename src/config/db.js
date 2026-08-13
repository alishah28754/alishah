const mysql = require('mysql2/promise');

/**
 * Database connection pool with singleton pattern for serverless.
 * Uses a single pool instance across all function invocations to
 * prevent connection limit exhaustion on Vercel/Serverless.
 *
 * PRIORITY ORDER:
 * 1. MYSQL_* variables (Railway auto-injected)
 * 2. DB_* variables (Hostinger, custom, local)
 * 3. Default fallback values
 *
 * Railway MySQL users: Just set MYSQLHOST, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE
 * and this will work automatically. No need to set DB_* variables.
 */
let pool = null;

function getPool() {
  if (!pool) {
    console.log('🔌 Creating MySQL connection pool...');

    // 🔍 Debug: Print all environment variables
    console.log('🔍 Environment Variables:');
    console.log(`   MYSQLHOST: ${process.env.MYSQLHOST || 'NOT SET'}`);
    console.log(`   DB_HOST: ${process.env.DB_HOST || 'NOT SET'}`);
    console.log(`   MYSQLUSER: ${process.env.MYSQLUSER || 'NOT SET'}`);
    console.log(`   DB_USER: ${process.env.DB_USER || 'NOT SET'}`);
    console.log(`   MYSQLPASSWORD: ${process.env.MYSQLPASSWORD ? '***SET***' : 'NOT SET'}`);
    console.log(`   DB_PASSWORD: ${process.env.DB_PASSWORD ? '***SET***' : 'NOT SET'}`);
    console.log(`   MYSQLDATABASE: ${process.env.MYSQLDATABASE || 'NOT SET'}`);
    console.log(`   DB_NAME: ${process.env.DB_NAME || 'NOT SET'}`);

    // ⭐ PRIORITY: MYSQL_* pehle, phir DB_*, phir defaults
    const host = process.env.MYSQLHOST || process.env.DB_HOST || 'localhost';
    const port = process.env.MYSQLPORT || process.env.DB_PORT || 3306;
    const user = process.env.MYSQLUSER || process.env.DB_USER || 'root';
    const password = process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || '';
    const database = process.env.MYSQLDATABASE || process.env.DB_NAME || 'ktex_db';

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
    const dbName = process.env.MYSQLDATABASE || process.env.DB_NAME || 'ktex_db';
    console.log(`✅ MySQL connected successfully: ${dbName}`);
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    console.error('   Check your MYSQL_* or DB_* environment variables.');
    console.error('   Current values:');
    console.error(`   MYSQLHOST: ${process.env.MYSQLHOST || 'NOT SET'}`);
    console.error(`   DB_HOST: ${process.env.DB_HOST || 'NOT SET'}`);
    console.error(`   MYSQLUSER: ${process.env.MYSQLUSER || 'NOT SET'}`);
    console.error(`   DB_USER: ${process.env.DB_USER || 'NOT SET'}`);
    console.error(`   MYSQLPASSWORD: ${process.env.MYSQLPASSWORD ? 'SET' : 'NOT SET'}`);
    console.error(`   DB_PASSWORD: ${process.env.DB_PASSWORD ? 'SET' : 'NOT SET'}`);
    console.error(`   MYSQLDATABASE: ${process.env.MYSQLDATABASE || 'NOT SET'}`);
    console.error(`   DB_NAME: ${process.env.DB_NAME || 'NOT SET'}`);
  }
})();

module.exports = poolInstance;
