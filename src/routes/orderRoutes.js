const router = require('express').Router();
const {
  createOrder, getMyOrders, getOrderByNumber, trackOrder, cancelOrder,
} = require('../controllers/orderController');
const { requireAuth, optionalAuth } = require('../middleware/auth');

// public tracking lookup (track_order_screen.dart) - must come before /:orderNumber
router.get('/track/:orderNumber', trackOrder);

// guest checkout allowed, but logged-in users get the order linked to their account
router.post('/', optionalAuth, createOrder);

router.get('/', requireAuth, getMyOrders);
router.get('/:orderNumber', optionalAuth, getOrderByNumber);
router.put('/:orderNumber/cancel', requireAuth, cancelOrder);

module.exports = router;
