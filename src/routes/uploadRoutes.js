const router = require('express').Router();
const upload = require('../middleware/upload');
const { uploadImage } = require('../controllers/uploadController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

// multipart/form-data, field name: "image", query: ?type=products|categories|banners
router.post('/', requireAuth, requireAdmin, upload.single('image'), uploadImage);

module.exports = router;
