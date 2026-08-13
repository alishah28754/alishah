const router = require('express').Router();
const {
  getProducts, getFlashSale, getNewArrivals, getForYou, getProductById,
  createProduct, updateProduct, deleteProduct,
} = require('../controllers/productController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

// Public routes (must be before /:id)
router.get('/flash-sale', getFlashSale);
router.get('/new-arrivals', getNewArrivals);
router.get('/for-you', getForYou);

router.get('/', getProducts);
router.get('/:id', getProductById);

// Admin only routes
router.post('/', requireAuth, requireAdmin, createProduct);
router.put('/:id', requireAuth, requireAdmin, updateProduct);
router.delete('/:id', requireAuth, requireAdmin, deleteProduct);

module.exports = router;