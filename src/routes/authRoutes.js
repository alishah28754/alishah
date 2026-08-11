const router = require('express').Router();
const { adminLogin, getMe, updateProfile } = require('../controllers/authController');
const { requireAuth } = require('../middleware/auth');

// Admin panel only -- plain email + password, checked against this table's
// password_hash column. The Flutter app never calls this; it still logs in
// directly with Firebase (see middleware/auth.js).
router.post('/login', adminLogin);

router.get('/me', requireAuth, getMe);
router.put('/profile', requireAuth, updateProfile);

module.exports = router;
