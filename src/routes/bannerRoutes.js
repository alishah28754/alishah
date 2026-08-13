const router = require('express').Router();
const { getBanners, createBanner, updateBanner, deleteBanner } = require('../controllers/bannerController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

router.get('/', getBanners);
router.post('/', requireAuth, requireAdmin, createBanner);
router.put('/:id', requireAuth, requireAdmin, updateBanner);
router.delete('/:id', requireAuth, requireAdmin, deleteBanner);

module.exports = router;