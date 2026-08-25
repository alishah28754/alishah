const router = require('express').Router();
const upload = require('../middleware/upload');
const { uploadFile } = require('../controllers/uploadController');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/admin');

// multipart/form-data, field name: "image" OR "video" (exactly one per
// request — the admin panel's image/video pickers each send their own
// field), query: ?type=products|categories|banners
router.post(
  '/',
  requireAuth,
  requireAdmin,
  upload.fields([
    { name: 'image', maxCount: 1 },
    { name: 'video', maxCount: 1 },
  ]),
  uploadFile
);

module.exports = router;
