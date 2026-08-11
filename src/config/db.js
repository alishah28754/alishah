const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'ktex_db',
  waitForConnections: true,
  // Lower than the old default (10) -- on serverless hosts (Vercel) many
  // short-lived function instances can each hold their own pool, so a high
  // per-instance limit risks hitting the remote MySQL server's own
  // max_connections cap under concurrent traffic. 3 is plenty for a single
  // request's queries.
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 3),
  queueLimit: 0,
  dateStrings: true,
  enableKeepAlive: true,
});

// Quick connectivity check on boot (does not crash the app, just logs)
(async () => {
  try {
    const conn = await pool.getConnection();
    console.log('✅ MySQL connected:', process.env.DB_NAME || 'ktex_db');
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    console.error('   Check your .env DB_HOST/DB_USER/DB_PASSWORD/DB_NAME values.');
  }
})();

module.exports = pool;
