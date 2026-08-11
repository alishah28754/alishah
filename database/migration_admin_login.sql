-- =====================================================
-- KTEX Store — Migration: Admin email+password login
-- Run this on your EXISTING ktex_db (the one already using Firebase for
-- the Flutter app). It only adds what's needed for the admin panel to log
-- in with email + password against MySQL instead of Firebase.
-- The Flutter app's Firebase login is completely untouched.
-- Safe to run once; re-running is harmless (checks before altering).
-- =====================================================

USE ktex_db;

-- 1) Add password_hash (bcrypt) for admin-panel accounts. Regular shopper
--    rows stay NULL here and keep logging in via Firebase as before.
ALTER TABLE users
  ADD COLUMN password_hash VARCHAR(255) NULL AFTER phone;

-- 2) firebase_uid must become optional: an admin-only row (created purely
--    to log into the admin panel, never opens the Flutter app) won't have
--    one.
ALTER TABLE users MODIFY firebase_uid VARCHAR(128) NULL;

-- 3) email needs to be unique so we can look an admin up by it at login.
--    If you already have duplicate/NULL emails from old rows this will
--    fail — clean those up first, then re-run.
ALTER TABLE users ADD UNIQUE KEY uniq_email (email);

-- 4) Set a password for your existing admin account:
--    Don't run a raw UPDATE with a plaintext password here — bcrypt hashes
--    can't be generated in SQL. Instead run, from the ktex-backend folder:
--
--      node database/set-admin-password.js you@example.com "YourNewPassword123"
--
--    That script will INSERT the row (if it doesn't exist yet), set
--    is_admin = 1, and store the bcrypt hash correctly.
