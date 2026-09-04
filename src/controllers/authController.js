const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { sendOtpEmail } = require('../services/mailService');
const admin = require('../config/firebase'); // adjust path to your firebase.js location

/**
 * NOTE on auth (UPDATED):
 * - The Flutter app (shoppers) now supports email+password (JWT checked
 *   against users.password_hash) AND any Firebase social provider
 *   (Google, Facebook, etc.) via socialLogin below, verified through the
 *   Firebase Admin SDK and exchanged for our own JWT.
 * - socialLogin matches users by firebase_uid first, falling back to
 *   email only to link an existing email/password row to a new Firebase
 *   login (so Google/Facebook accounts with the same email don't get
 *   silently merged with each other without going through firebase_uid).
 * - The KTEX admin panel uses email+password JWT only.
 * - adminLogin issues a JWT with type:'admin'; customerLogin/verifyOtp/
 *   socialLogin issue one with type:'customer'. requireAuth accepts either.
 */

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/* POST /api/auth/admin-login - unchanged */
const adminLogin = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return error(res, 'Email and password are required.', 400);
  }

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  if (!user || !user.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
    return error(res, 'Invalid email or password.', 401);
  }

  if (!user.is_admin) {
    return error(res, 'This account does not have admin access.', 403);
  }

  const token = jwt.sign(
    { id: user.id, type: 'admin' },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return success(res, {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      is_admin: !!user.is_admin,
    },
  }, 'Logged in.');
});

/* POST /api/auth/signup - public. Creates an unverified customer row + sends OTP. */
const signup = asyncHandler(async (req, res) => {
  const { name, email, password, phone } = req.body;

  if (!name || !email || !password) {
    return error(res, 'Name, email and password are required.', 400);
  }

  const [existing] = await pool.query('SELECT id, is_email_verified FROM users WHERE email = ? LIMIT 1', [email]);

  if (existing.length > 0 && existing[0].is_email_verified) {
    return error(res, 'This email is already registered. Please log in.', 400);
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const otp = generateOtp();
  const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

  if (existing.length > 0) {
    // Row exists but was never verified (abandoned signup) -- overwrite it.
    await pool.query(
      `UPDATE users SET name = ?, password_hash = ?, phone = ?, provider = 'email',
       otp_code = ?, otp_expires_at = ? WHERE email = ?`,
      [name, passwordHash, phone || null, otp, otpExpiry, email]
    );
  } else {
    await pool.query(
      `INSERT INTO users (name, email, phone, password_hash, provider, is_email_verified, otp_code, otp_expires_at)
       VALUES (?, ?, ?, ?, 'email', 0, ?, ?)`,
      [name, email, phone || null, passwordHash, otp, otpExpiry]
    );
  }

  await sendOtpEmail(email, otp);

  return success(res, { email }, 'OTP sent to your email. Please verify to activate your account.');
});

/* POST /api/auth/verify-otp - public. Verifies the code and logs the user in. */
const verifyOtp = asyncHandler(async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return error(res, 'Email and OTP are required.', 400);
  }

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  if (!user) return error(res, 'User not found.', 404);
  if (user.is_email_verified) return error(res, 'Already verified. Please log in.', 400);
  if (user.otp_code !== otp) return error(res, 'Invalid OTP.', 400);
  if (new Date() > new Date(user.otp_expires_at)) return error(res, 'OTP expired. Please request a new one.', 400);

  await pool.query(
    'UPDATE users SET is_email_verified = 1, otp_code = NULL, otp_expires_at = NULL WHERE email = ?',
    [email]
  );

  const token = jwt.sign(
    { id: user.id, type: 'customer' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '30d' }
  );

  return success(res, {
    token,
    user: { id: user.id, name: user.name, email: user.email, phone: user.phone },
  }, 'Account verified.');
});

/* POST /api/auth/resend-otp - public */
const resendOtp = asyncHandler(async (req, res) => {
  const { email } = req.body;
  if (!email) return error(res, 'Email is required.', 400);

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  if (!user) return error(res, 'User not found.', 404);
  if (user.is_email_verified) return error(res, 'Already verified. Please log in.', 400);

  const otp = generateOtp();
  const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

  await pool.query('UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE email = ?', [otp, otpExpiry, email]);
  await sendOtpEmail(email, otp);

  return success(res, null, 'OTP resent.');
});

/* POST /api/auth/customer-login - public */
const customerLogin = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return error(res, 'Email and password are required.', 400);
  }

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  if (!user || !user.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
    return error(res, 'Invalid email or password.', 401);
  }

  if (!user.is_email_verified) {
    return error(res, 'Please verify your email first.', 403);
  }

  const token = jwt.sign(
    { id: user.id, type: 'customer' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '30d' }
  );

  return success(res, {
    token,
    user: { id: user.id, name: user.name, email: user.email, phone: user.phone },
  }, 'Logged in.');
});

/* POST /api/auth/google-login - public. Verifies a Firebase ID token from
 * ANY Firebase provider (Google, Facebook, etc.) and creates/logs in the
 * matching user. Route path kept as "google-login" for backward
 * compatibility with the existing app build; the app can also call this
 * for Facebook Sign-In without any app-side route change. */
const socialLogin = asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return error(res, 'ID token is required.', 400);
  }

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch (err) {
    return error(res, 'Invalid or expired token.', 401);
  }

  const { uid, email, name, phone_number, firebase } = decoded;
  const provider = firebase?.sign_in_provider || 'unknown'; // e.g. 'google.com', 'facebook.com'

  if (!email) {
    return error(res, 'Account has no email.', 400);
  }

  // Match by firebase_uid first (authoritative for this specific
  // provider sign-in). Fall back to email only to link a pre-existing
  // email/password row that hasn't been tied to a firebase_uid yet.
  const [byUid] = await pool.query('SELECT * FROM users WHERE firebase_uid = ? LIMIT 1', [uid]);
  let user = byUid[0];

  if (!user) {
    const [byEmail] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    user = byEmail[0];

    if (!user) {
      // Brand new user.
      const [result] = await pool.query(
        `INSERT INTO users (name, email, phone, provider, firebase_uid, is_email_verified)
         VALUES (?, ?, ?, ?, ?, 1)`,
        [name || 'User', email, phone_number || null, provider, uid]
      );
      const [newRows] = await pool.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
      user = newRows[0];
    } else {
      // Existing row (e.g. abandoned email signup, or first-time social
      // login on an email/password account) - link this firebase_uid to it.
      await pool.query(
        'UPDATE users SET firebase_uid = ?, is_email_verified = 1 WHERE id = ?',
        [uid, user.id]
      );
      user.firebase_uid = uid;
      user.is_email_verified = 1;
    }
  }

  const token = jwt.sign(
    { id: user.id, type: 'customer' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '30d' }
  );

  return success(res, {
    token,
    user: { id: user.id, name: user.name, email: user.email, phone: user.phone },
  }, 'Logged in.');
});

/* POST /api/auth/forgot-password - public. Sends a 6-digit reset code to
 * the account's email, reusing the same otp_code/otp_expires_at columns
 * as signup. Does NOT touch is_email_verified. */
const forgotPassword = asyncHandler(async (req, res) => {
  const { email } = req.body;
  if (!email) return error(res, 'Email is required.', 400);

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  // Don't reveal whether the email exists — respond the same way either way.
  if (!user) {
    return success(res, null, 'If that email is registered, a reset code has been sent.');
  }

  const otp = generateOtp();
  const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

  await pool.query('UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE email = ?', [otp, otpExpiry, email]);
  await sendOtpEmail(email, otp);

  return success(res, null, 'If that email is registered, a reset code has been sent.');
});

/* POST /api/auth/reset-password - public. Verifies the code and sets the
 * new password in one call, then clears the code so it can't be reused. */
const resetPassword = asyncHandler(async (req, res) => {
  const { email, otp, newPassword } = req.body;

  if (!email || !otp || !newPassword) {
    return error(res, 'Email, OTP and new password are required.', 400);
  }
  if (newPassword.length < 6) {
    return error(res, 'Password must be at least 6 characters.', 400);
  }

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
  const user = rows[0];

  if (!user) return error(res, 'Invalid OTP.', 400);
  if (!user.otp_code || user.otp_code !== otp) return error(res, 'Invalid OTP.', 400);
  if (!user.otp_expires_at || new Date() > new Date(user.otp_expires_at)) {
    return error(res, 'OTP expired. Please request a new one.', 400);
  }

  const passwordHash = await bcrypt.hash(newPassword, 10);

  await pool.query(
    'UPDATE users SET password_hash = ?, otp_code = NULL, otp_expires_at = NULL WHERE email = ?',
    [passwordHash, email]
  );

  return success(res, null, 'Password updated. Please log in with your new password.');
});

/* GET /api/auth/me - protected, unchanged */
const getMe = asyncHandler(async (req, res) => {
  return success(res, req.user);
});

/* PUT /api/auth/profile - protected, unchanged */
const updateProfile = asyncHandler(async (req, res) => {
  const { name, phone } = req.body;
  const fields = [];
  const values = [];

  if (name) { fields.push('name = ?'); values.push(name); }
  if (phone !== undefined) { fields.push('phone = ?'); values.push(phone); }

  if (fields.length === 0) {
    return error(res, 'Nothing to update.', 400);
  }

  values.push(req.user.id);
  await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);

  const [rows] = await pool.query(
    'SELECT id, name, email, phone, is_admin FROM users WHERE id = ?',
    [req.user.id]
  );
  return success(res, rows[0], 'Profile updated.');
});

/* PUT /api/auth/fcm-token - protected. Registers/updates this device's FCM
 * token against the JWT-authenticated user row. Read by
 * utils/pushNotifications.js (sendPushToMysqlUser) when sending order-status
 * pushes. De-duplicates so repeated calls with the same token are a no-op. */
const updateFcmToken = asyncHandler(async (req, res) => {
  const { token } = req.body;
  if (!token) return error(res, 'FCM token is required.', 400);

  const [rows] = await pool.query('SELECT fcm_tokens FROM users WHERE id = ? LIMIT 1', [req.user.id]);
  let tokens = [];
  try {
    tokens = rows[0]?.fcm_tokens ? JSON.parse(rows[0].fcm_tokens) : [];
    if (!Array.isArray(tokens)) tokens = [];
  } catch (_) {
    tokens = [];
  }

  if (!tokens.includes(token)) {
    tokens.push(token);
    await pool.query('UPDATE users SET fcm_tokens = ? WHERE id = ?', [JSON.stringify(tokens), req.user.id]);
  }

  return success(res, null, 'FCM token registered.');
});

/* DELETE /api/auth/delete-account - protected. Customer deletes their own
 * account. Deletes the Firebase user first so that a re-login with the same
 * Gmail/Facebook does not match the old firebase_uid or email row and is
 * forced through signup again as a brand-new account. */
const deleteMyAccount = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT firebase_uid, is_admin FROM users WHERE id = ?', [req.user.id]);
  if (rows.length === 0) return error(res, 'User not found.', 404);
  if (rows[0].is_admin) return error(res, 'Admin accounts cannot be self-deleted.', 400);

  if (rows[0].firebase_uid) {
    try {
      await admin.auth().deleteUser(rows[0].firebase_uid);
    } catch (err) {
      console.error('⚠️ Firebase user deletion failed (continuing with DB delete):', err.message);
    }
  }

  await pool.query('DELETE FROM users WHERE id = ?', [req.user.id]);
  return success(res, null, 'Account deleted.');
});

module.exports = {
  adminLogin,
  signup,
  verifyOtp,
  resendOtp,
  customerLogin,
  googleLogin: socialLogin, // route path unchanged; now handles Google + Facebook + any Firebase provider
  forgotPassword,
  resetPassword,
  getMe,
  updateProfile,
  updateFcmToken,
  deleteMyAccount,
};
