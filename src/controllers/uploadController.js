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

  const type = ['products', 'categories', 'banners'].includes(req.query.type) ? req.query.type : 'products';

  const uploadStream = cloudinary.uploader.upload_stream(
    {
      folder: `ktex/${type}`,
      resource_type: 'image',
    },
    (err, result) => {
      if (err) {
        console.error('Cloudinary upload failed:', err.message);
        return error(res, 'Image upload failed. Please try again.', 500);
      }
      return success(
        res,
        { url: result.secure_url, path: result.public_id },
        'Image uploaded.',
        201
      );
    }
  );

  uploadStream.end(req.file.buffer);
};

module.exports = { uploadImage };