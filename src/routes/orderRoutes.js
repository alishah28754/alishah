const router = require('express').Router();
const {
  createOrder, getMyOrders, trackOrder, cancelOrder, deleteOrder,
} = require('../controllers/orderController');
const { requireAuth, optionalAuth } = require('../middleware/auth');

// Public tracking (must be before /:orderNumber)
router.get('/track/:orderNumber', trackOrder);

// Guest checkout allowed
router.post('/', optionalAuth, createOrder);

// Protected routes
router.get('/', requireAuth, getMyOrders);
router.put('/:orderNumber/cancel', requireAuth, cancelOrder);
router.delete('/:orderNumber', requireAuth, deleteOrder);

module.exports = router;
