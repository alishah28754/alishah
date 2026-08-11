-- Only needed if you have OLD image URLs saved with http:// (from before the
-- Cloudinary migration). New uploads go straight to Cloudinary and don't
-- need this. Safe to re-run.

UPDATE products
SET image_url = REPLACE(image_url, 'http://', 'https://')
WHERE image_url LIKE 'http://%ngrok%';

UPDATE categories
SET image_url = REPLACE(image_url, 'http://', 'https://')
WHERE image_url LIKE 'http://%ngrok%';

UPDATE banners
SET image_url = REPLACE(image_url, 'http://', 'https://')
WHERE image_url LIKE 'http://%ngrok%';
