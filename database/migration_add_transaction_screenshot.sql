-- =====================================================
-- Migration: add transaction_screenshot_url to orders
-- Run this against the LIVE database (not just schema.sql, which is
-- reference/historical only — see the schema-drift note already flagged
-- for categories.parent_id). Safe to run once; re-running will error with
-- "duplicate column" if it already exists, which just means it's done.
-- =====================================================

USE ktex_db;

-- Placed after transaction_id since that column is confirmed present in
-- schema.sql. account_title/account_number are referenced by
-- orderController.js's INSERT but aren't in schema.sql at all — another
-- sign of schema drift on the live DB. If your live `orders` table doesn't
-- have transaction_id either, drop the AFTER clause below entirely.
ALTER TABLE orders
  ADD COLUMN transaction_screenshot_url VARCHAR(500) NULL
  AFTER transaction_id;
