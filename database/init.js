/**
 * One-time helper: creates the database + tables from schema.sql
 * Usage: npm run db:init
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

async function run() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });

  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    console.log('Running schema.sql ...');
    await connection.query(schemaSql);
    console.log('✅ Database and tables created successfully.');

    const seedFlag = process.argv.includes('--seed');
    if (seedFlag) {
      const seedPath = path.join(__dirname, 'seed.sql');
      const seedSql = fs.readFileSync(seedPath, 'utf8');
      console.log('Running seed.sql ...');
      await connection.query(seedSql);
      console.log('✅ Seed data inserted.');
    }
  } catch (err) {
    console.error('❌ Database init failed:', err.message);
    process.exitCode = 1;
  } finally {
    await connection.end();
  }
}

run();
