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
// NOTE: the shared upload middleware's fileFilter only allows fields named
// "image" or "video" — the multipart field must be sent as "image" (not
// "screenshot") from the client, or this will 500 with "Unexpected field".
router.post('/upload-screenshot', optionalAuth, upload.single('image'), uploadOrderScreenshot);

// Guest checkout allowed
router.post('/', optionalAuth, createOrder);

// Protected routes
router.get('/', requireAuth, getMyOrders);
// Guest-owned orders (user_id NULL) can be cancelled by anyone holding the
// order number — same trust model as the public /track/:orderNumber route
// above. Logged-in users' orders are still protected by the ownership
// check inside cancelOrder itself.
router.put('/:orderNumber/cancel', optionalAuth, cancelOrder);
// Guest-owned orders (user_id NULL) can be deleted by anyone holding the
// order number, same trust model as cancel above.
router.delete('/:orderNumber', optionalAuth, deleteOrder);

module.exports = router;
