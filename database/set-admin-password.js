/**
 * One-time helper: creates (or updates) an admin-panel login.
 *
 * Usage:
 *   node database/set-admin-password.js you@example.com "YourNewPassword123" ["Display Name"]
 *
 * - If a users row with that email already exists, its password_hash is
 *   updated and is_admin is set to 1 (the row keeps its existing
 *   firebase_uid / orders / etc. untouched).
 * - If no row exists yet, a new admin-only row is created (firebase_uid
 *   left NULL — this account is never meant to log into the Flutter app).
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');

async function run() {
  const [, , email, password, name] = process.argv;

  if (!email || !password) {
    console.error('Usage: node database/set-admin-password.js <email> <password> ["Display Name"]');
    process.exit(1);
  }
  if (password.length < 8) {
    console.error('Password must be at least 8 characters.');
    process.exit(1);
  }

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'ktex_db',
  });

  try {
    const hash = await bcrypt.hash(password, 10);
    const [existing] = await connection.query('SELECT id FROM users WHERE email = ?', [email]);

    if (existing.length > 0) {
      await connection.query(
        'UPDATE users SET password_hash = ?, is_admin = 1, name = COALESCE(?, name) WHERE email = ?',
        [hash, name || null, email]
      );
      console.log(`✅ Updated existing user (id ${existing[0].id}) — password set, is_admin = 1.`);
    } else {
      const [result] = await connection.query(
        'INSERT INTO users (name, email, password_hash, is_admin) VALUES (?, ?, ?, 1)',
        [name || email.split('@')[0], email, hash]
      );
      console.log(`✅ Created new admin user (id ${result.insertId}).`);
    }

    console.log(`You can now log in to the admin panel with:\n  email:    ${email}\n  password: (the one you just set)`);
  } finally {
    await connection.end();
  }
}

run().catch((err) => {
  console.error('❌ Failed:', err.message);
  process.exit(1);
});
