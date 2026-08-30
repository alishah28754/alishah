const express = require('express');
const router = express.Router();
const { requireAuth, optionalAuth } = require('../middleware/auth');
const multer = require('multer');

const orderController = require('../controllers/orderController');
const {
  createOrder = () => {},
  getMyOrders = () => {},
  trackOrder = () => {},
  cancelOrder = () => {},
  deleteOrder = () => {},
  uploadOrderScreenshot = () => {},
  updateOrderStatus = () => {},
  getAllOrders = () => {},
} = orderController;

// Simple admin-only gate: requireAuth already attaches req.user
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.is_admin) {
    return res.status(403).json({ success: false, message: 'Admin access required.' });
  }
  next();
}

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only images are allowed'), false);
    }
  }
});

// Guest/User routes
// optionalAuth: guest checkout still works, but if a valid JWT is sent
// (logged-in users always send one via ApiService's auth:true), req.user
// gets populated so createOrder correctly links the order to the user_id.
// Without this, every order was saved with user_id = NULL regardless of
// login state, which silently broke order-status push notifications
// (adminController.updateOrderStatus only sends a push when user_id is set).
router.post('/', optionalAuth, createOrder);
router.get('/my-orders', requireAuth, getMyOrders);
router.get('/track/:orderNumber', trackOrder);
router.put('/:orderNumber/cancel', cancelOrder);
router.delete('/:orderNumber', deleteOrder);
router.post('/upload-screenshot', upload.single('screenshot'), uploadOrderScreenshot);

// Admin routes
if (typeof updateOrderStatus === 'function') {
  router.put('/:orderNumber/status', requireAuth, requireAdmin, updateOrderStatus);
} else {
  console.warn('⚠️ updateOrderStatus function not found - route skipped');
}
if (typeof getAllOrders === 'function') {
  router.get('/admin/all', requireAuth, requireAdmin, getAllOrders);
} else {
  console.warn('⚠️ getAllOrders function not found - route skipped');
}

module.exports = router;
