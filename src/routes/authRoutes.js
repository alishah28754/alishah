const router = require('express').Router();
const { adminLogin, getMe, updateProfile } = require('../controllers/authController');
const { requireAuth } = require('../middleware/auth');

// Admin panel login (email + password)
router.post('/login', adminLogin);

// Protected routes
router.get('/me', requireAuth, getMe);
router.put('/profile', requireAuth, updateProfile);

module.exports = router;