const multer = require('multer');
const path = require('path');

/**
 * Multer configuration for memory storage.
 * Files are stored in memory then streamed to Cloudinary.
 * This prevents issues with ephemeral storage on serverless hosts.
 */
const storage = multer.memoryStorage();

// ✅ FIX: added common video extensions. Previously this only allowed image
// extensions, so any video file (e.g. a product color's optional video) was
// rejected right here at the middleware level, before it ever reached
// uploadController.js — regardless of what the frontend sent.
function fileFilter(req, file, cb) {
  const allowed = /jpeg|jpg|png|webp|gif|mp4|mov|webm|mkv|avi/;
  const isAllowed = allowed.test(path.extname(file.originalname).toLowerCase());
  if (isAllowed) return cb(null, true);
  cb(new Error('Only image (jpg, jpeg, png, webp, gif) or video (mp4, mov, webm, mkv, avi) files are allowed'));
}

// NOTE: videos are typically much larger than images. If you keep a single
// shared UPLOAD_MAX_SIZE_MB for both, make sure it's set high enough for
// your product videos (e.g. 50+) or split this into two multer instances
// with different limits — one for images, one for videos.
const maxSizeMb = Number(process.env.UPLOAD_MAX_SIZE_MB || 5);

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: maxSizeMb * 1024 * 1024 },
});

module.exports = upload;
