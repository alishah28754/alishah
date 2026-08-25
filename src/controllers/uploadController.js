const cloudinary = require('../config/cloudinary');
const { success, error } = require('../utils/apiResponse');

/**
 * POST /api/upload - Admin only, multipart field "image" OR "video".
 * upload.fields() (see uploadRoutes.js) puts each field's files under
 * req.files.image / req.files.video instead of the single req.file we had
 * when this only handled images — so figure out which one actually came in.
 */
const uploadFile = (req, res) => {
  const imageFile = req.files?.image?.[0];
  const videoFile = req.files?.video?.[0];
  const file = imageFile || videoFile;
  const resourceType = videoFile ? 'video' : 'image';

  if (!file) {
    return error(res, 'No file uploaded. Use multipart field name "image" or "video".', 400);
  }

  // Cloudinary is secondary - warn but don't crash if not configured
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    return error(res, 'Cloudinary is not configured. Please set CLOUDINARY_* env vars.', 503);
  }

  const type = ['products', 'categories', 'banners'].includes(req.query.type) ? req.query.type : 'products';
  // Videos get their own subfolder so they don't mix in with product
  // photos in the Cloudinary media library.
  const folder = resourceType === 'video' ? `ktex/${type}/videos` : `ktex/${type}`;

  const uploadStream = cloudinary.uploader.upload_stream(
    {
      folder,
      resource_type: resourceType,
    },
    (err, result) => {
      if (err) {
        console.error(`Cloudinary ${resourceType} upload failed:`, err.message);
        return error(res, `${resourceType === 'video' ? 'Video' : 'Image'} upload failed. Please try again.`, 500);
      }
      return success(
        res,
        { url: result.secure_url, path: result.public_id },
        `${resourceType === 'video' ? 'Video' : 'Image'} uploaded.`,
        201
      );
    }
  );

  uploadStream.end(file.buffer);
};

module.exports = { uploadFile };
