const express = require('express');
const router = express.Router();
const { protect, admin } = require('../middleware/auth');
const multer = require('multer');
const {
  createOrder,
  getMyOrders,
  trackOrder,
  cancelOrder,
  deleteOrder,
  uploadOrderScreenshot,
  updateOrderStatus,
  getAllOrders,
} = require('../controllers/orderController');

// Multer setup for screenshot upload (memory storage)
const storage = multer.memoryStorage();
const upload = multer({ 
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only images are allowed'), false);
    }
  }
});

// Guest/User routes
router.post('/', createOrder);
router.get('/my-orders', protect, getMyOrders);
router.get('/track/:orderNumber', trackOrder);
router.put('/:orderNumber/cancel', cancelOrder);
router.delete('/:orderNumber', deleteOrder);
router.post('/upload-screenshot', upload.single('screenshot'), uploadOrderScreenshot);

// ✅ Admin routes
router.put('/:orderNumber/status', protect, admin, updateOrderStatus);
router.get('/admin/all', protect, admin, getAllOrders);

module.exports = router;
