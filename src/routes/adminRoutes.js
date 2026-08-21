const router = require('express').Router();
const {
  getDashboardStats, getAllOrders, updateOrderStatus, getAllUsers, deleteUser, toggleAdmin, toggleActive,
} = require('../controllers/adminController');
const { deleteOrder } = require('../controllers/orderController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

router.use(requireAuth, requireAdmin); // every /api/admin/* route requires an admin

router.get('/stats', getDashboardStats);

router.get('/orders', getAllOrders);
router.put('/orders/:orderNumber/status', updateOrderStatus);
// Reuses orderController.deleteOrder directly — since requireAdmin has
// already run above, req.user.is_admin is guaranteed true here, so that
// function's admin-bypass path applies: any order (guest or logged-in
// customer) can be deleted from here as long as it's Cancelled or Delivered.
router.delete('/orders/:orderNumber', deleteOrder);

router.get('/users', getAllUsers);
router.delete('/users/:id', deleteUser);
router.put('/users/:id/toggle-admin', toggleAdmin);
router.put('/users/:id/toggle-active', toggleActive);

module.exports = router;
