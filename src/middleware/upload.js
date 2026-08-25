const multer = require('multer');
const path = require('path');

/**
 * Multer configuration for memory storage.
 * Files are stored in memory then streamed to Cloudinary.
 * This prevents issues with ephemeral storage on serverless hosts.
 */
const storage = multer.memoryStorage();

function fileFilter(req, file, cb) {
  const allowed = /jpeg|jpg|png|webp|gif/;
  const isAllowed = allowed.test(path.extname(file.originalname).toLowerCase());
  if (isAllowed) return cb(null, true);
  cb(new Error('Only image files (jpg, jpeg, png, webp, gif) are allowed'));
}

const maxSizeMb = Number(process.env.UPLOAD_MAX_SIZE_MB || 5);

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: maxSizeMb * 1024 * 1024 },
});

module.exports = upload;
