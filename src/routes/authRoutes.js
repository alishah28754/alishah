const router = require('express').Router();
const {
  adminLogin, signup, verifyOtp, resendOtp, customerLogin, googleLogin, getMe, updateProfile, updateFcmToken,
} = require('../controllers/authController');
const { requireAuth } = require('../middleware/auth');

// Admin panel login (email + password)
router.post('/login', adminLogin);

// Customer auth (Flutter app)
router.post('/signup', signup);
router.post('/verify-otp', verifyOtp);
router.post('/resend-otp', resendOtp);
router.post('/customer-login', customerLogin);
router.post('/google-login', googleLogin);

// Protected routes (both admin + customer)
router.get('/me', requireAuth, getMe);
router.put('/profile', requireAuth, updateProfile);
router.put('/fcm-token', requireAuth, updateFcmToken);

module.exports = router;
