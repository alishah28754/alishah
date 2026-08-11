const router = require('express').Router();
const {
  getDashboardStats, getAllOrders, updateOrderStatus, getAllUsers, deleteUser, toggleAdmin,
} = require('../controllers/adminController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

router.use(requireAuth, requireAdmin); // every /api/admin/* route requires an admin

router.get('/stats', getDashboardStats);

router.get('/orders', getAllOrders);
router.put('/orders/:orderNumber/status', updateOrderStatus);

router.get('/users', getAllUsers);
router.delete('/users/:id', deleteUser);
router.put('/users/:id/toggle-admin', toggleAdmin);

module.exports = router;
