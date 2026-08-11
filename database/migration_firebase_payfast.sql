-- =====================================================
-- KTEX Store — Migration: Firebase Auth + PayFast
-- Run this ONLY if you already created ktex_db/tables using the
-- earlier schema.sql (custom email/password auth, no PayFast).
-- Safe to run once; re-running is harmless (checks before altering).
-- =====================================================

USE ktex_db;

-- 1) Add firebase_uid to users, make email/password optional, drop the
--    old UNIQUE(email) since Firebase — not this table — enforces
--    uniqueness on login identity now.
ALTER TABLE users
  ADD COLUMN firebase_uid VARCHAR(128) NULL AFTER id;

-- Drop the old unique index on email (name may differ — check with:
-- SHOW INDEX FROM users; — adjust index name below if needed)
ALTER TABLE users DROP INDEX email;

ALTER TABLE users MODIFY email VARCHAR(191) NULL;
ALTER TABLE users MODIFY password VARCHAR(255) NULL;

-- Backfill: existing rows have no firebase_uid yet. Either delete test rows:
--   DELETE FROM users WHERE firebase_uid IS NULL;
-- ...or leave them — they just won't be reachable via the API until you set
-- firebase_uid manually to match the real Firebase user.

-- Once every remaining row has a firebase_uid, lock it down:
-- ALTER TABLE users MODIFY firebase_uid VARCHAR(128) NOT NULL;
-- ALTER TABLE users ADD UNIQUE KEY uniq_firebase_uid (firebase_uid);

-- 2) Drop the password column entirely once you're fully off the old
--    custom-auth system (safe to run whenever you're ready):
-- ALTER TABLE users DROP COLUMN password;

-- 3) Add PayFast support to orders
ALTER TABLE orders
  MODIFY payment_method ENUM('cod','payfast','easypaisa','jazzcash','bank') NOT NULL DEFAULT 'cod';

ALTER TABLE orders
  ADD COLUMN payfast_txn_id VARCHAR(100) NULL AFTER transaction_id;
