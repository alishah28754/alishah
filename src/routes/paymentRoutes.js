const router = require('express').Router();
const {
  initiatePayfast, renderCheckoutForm, paymentSuccess, paymentFailure, handlePayfastCallback,
} = require('../controllers/paymentController');
const { optionalAuth } = require('../middleware/auth');

// PayFast routes (secondary priority)
router.post('/payfast/initiate', optionalAuth, initiatePayfast);
router.get('/payfast/checkout-form/:orderNumber', renderCheckoutForm);
router.get('/payfast/success', paymentSuccess);
router.get('/payfast/failure', paymentFailure);
router.post('/payfast/callback', handlePayfastCallback);
router.get('/payfast/callback', handlePayfastCallback);

module.exports = router;