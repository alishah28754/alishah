const mysql = require('mysql2/promise');

// Railway MySQL uses MYSQLHOST, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE
// Local development uses DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
const pool = mysql.createPool({
  host: process.env.MYSQLHOST || process.env.DB_HOST || 'localhost',
  port: process.env.MYSQLPORT || process.env.DB_PORT || 3306,
  user: process.env.MYSQLUSER || process.env.DB_USER || 'root',
  password: process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || '',
  database: process.env.MYSQLDATABASE || process.env.DB_NAME || 'ktex_db',
  waitForConnections: true,
  // Railway internal connection ke liye lower limit
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 3),
  queueLimit: 0,
  dateStrings: true,
  enableKeepAlive: true,
  // Railway MySQL ke liye extra options
  connectTimeout: 10000,
  ssl: {
    rejectUnauthorized: false  // Railway internal ke liye
  }
});

// Quick connectivity check on boot (does not crash the app, just logs)
(async () => {
  try {
    const conn = await pool.getConnection();
    const dbName = process.env.MYSQLDATABASE || process.env.DB_NAME || 'ktex_db';
    console.log(`✅ MySQL connected: ${dbName}`);
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    console.error('   Check your MYSQLHOST/MYSQLUSER/MYSQLPASSWORD/MYSQLDATABASE values.');
  }
})();

module.exports = pool;
