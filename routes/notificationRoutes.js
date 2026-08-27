const router = require('express').Router();
const { registerToken, removeToken } = require('../controllers/notificationController');
const { requireAuth } = require('../middleware/auth');

router.post('/token', requireAuth, registerToken);
router.delete('/token', requireAuth, removeToken);

module.exports = router;
