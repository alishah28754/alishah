const router = require('express').Router();
const {
  createOrder, getMyOrders, trackOrder, cancelOrder, deleteOrder, uploadOrderScreenshot,
} = require('../controllers/orderController');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Public tracking (must be before /:orderNumber)
router.get('/track/:orderNumber', trackOrder);

// Screenshot upload for checkout — guest-friendly (same as order creation
// below), so a customer checking out without logging in can still attach
// their transaction proof before placing the order.
router.post('/upload-screenshot', optionalAuth, upload.single('screenshot'), uploadOrderScreenshot);

// Guest checkout allowed
router.post('/', optionalAuth, createOrder);

// Protected routes
router.get('/', requireAuth, getMyOrders);
router.put('/:orderNumber/cancel', requireAuth, cancelOrder);
router.delete('/:orderNumber', requireAuth, deleteOrder);

module.exports = router;
