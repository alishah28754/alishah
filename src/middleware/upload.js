const multer = require('multer');
const path = require('path');

// Files are held in memory only, then streamed straight to Cloudinary in
// uploadController.js. Nothing is written to local disk -- important because
// most cheap/free Node hosts (Render, Vercel, etc.) wipe local disk on every
// restart or redeploy, which would otherwise silently delete every uploaded
// image.
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
