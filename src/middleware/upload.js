const multer = require('multer');
const path = require('path');

/**
 * Multer configuration for memory storage.
 * Files are stored in memory then streamed to Cloudinary.
 * This prevents issues with ephemeral storage on serverless hosts.
 */
const storage = multer.memoryStorage();

const IMAGE_EXT = /jpeg|jpg|png|webp|gif/;
// Product videos: accept the common formats a phone/camera or admin would
// realistically upload. Cloudinary transcodes on its end, so we don't need
// to be exhaustive here.
const VIDEO_EXT = /mp4|mov|webm|mkv|avi|m4v/;

// Multer's fileFilter only tells us the field name + original filename
// (the file body streams in after this decision), so we key validation off
// the multipart field name: "image" must be an image, "video" must be a
// video. Anything else is rejected outright.
function fileFilter(req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();

  if (file.fieldname === 'video') {
    if (VIDEO_EXT.test(ext)) return cb(null, true);
    return cb(new Error('Only video files (mp4, mov, webm, mkv, avi, m4v) are allowed'));
  }

  if (file.fieldname === 'image') {
    if (IMAGE_EXT.test(ext)) return cb(null, true);
    return cb(new Error('Only image files (jpg, jpeg, png, webp, gif) are allowed'));
  }

  cb(new Error(`Unexpected field "${file.fieldname}". Use "image" or "video".`));
}

const maxImageSizeMb = Number(process.env.UPLOAD_MAX_SIZE_MB || 5);
// Videos are naturally much larger than product photos, so they get their
// own (higher) ceiling. Multer applies a single fileSize limit per request,
// so we use the larger of the two here and rely on fileFilter above plus
// the controller to keep each field honest about what it actually is.
const maxVideoSizeMb = Number(process.env.UPLOAD_VIDEO_MAX_SIZE_MB || 50);

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: Math.max(maxImageSizeMb, maxVideoSizeMb) * 1024 * 1024 },
});

module.exports = upload;
