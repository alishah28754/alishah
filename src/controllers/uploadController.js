const cloudinary = require('../config/cloudinary');
const { success, error } = require('../utils/apiResponse');

/** POST /api/upload - Admin only, multipart field "image" */
const uploadImage = (req, res) => {
  if (!req.file) {
    return error(res, 'No image file uploaded. Use multipart field name "image".', 400);
  }

  // Cloudinary is secondary - warn but don't crash if not configured
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    return error(res, 'Cloudinary is not configured. Please set CLOUDINARY_* env vars.', 503);
  }

  // ✅ FIX: added 'videos' to the allowed type list. Previously any
  // ?type=videos request silently fell back to 'products', and — more
  // importantly — resource_type below was hardcoded to 'image', which
  // makes Cloudinary reject/corrupt actual video uploads.
  const type = ['products', 'categories', 'banners', 'videos'].includes(req.query.type)
    ? req.query.type
    : 'products';

  // ✅ FIX: pick the correct Cloudinary resource_type based on what's being
  // uploaded, instead of always sending 'image'.
  const resourceType = type === 'videos' ? 'video' : 'image';

  const uploadStream = cloudinary.uploader.upload_stream(
    {
      folder: `ktex/${type}`,
      resource_type: resourceType,
    },
    (err, result) => {
      if (err) {
        console.error('Cloudinary upload failed:', err.message);
        return error(res, 'Upload failed. Please try again.', 500);
      }
      return success(
        res,
        { url: result.secure_url, path: result.public_id },
        'Upload complete.',
        201
      );
    }
  );

  uploadStream.end(req.file.buffer);
};

module.exports = { uploadImage };
