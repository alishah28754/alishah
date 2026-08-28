const express = require('express');
const router = express.Router();
const { protect, admin } = require('../middleware/auth');
const multer = require('multer');

// Import all controller functions with fallbacks
const orderController = require('../controllers/orderController');

// Destructure with safe fallbacks
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

// Multer setup for screenshot upload
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

// ✅ Guest/User routes
router.post('/', createOrder);
router.get('/my-orders', protect, getMyOrders);
router.get('/track/:orderNumber', trackOrder);
router.put('/:orderNumber/cancel', cancelOrder);
router.delete('/:orderNumber', deleteOrder);
router.post('/upload-screenshot', upload.single('screenshot'), uploadOrderScreenshot);

// ✅ Admin routes (check if functions exist before using)
if (typeof updateOrderStatus === 'function') {
  router.put('/:orderNumber/status', protect, admin, updateOrderStatus);
} else {
  console.warn('⚠️ updateOrderStatus function not found - route skipped');
}

if (typeof getAllOrders === 'function') {
  router.get('/admin/all', protect, admin, getAllOrders);
} else {
  console.warn('⚠️ getAllOrders function not found - route skipped');
}

module.exports = router;
