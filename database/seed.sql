-- =====================================================
-- KTEX Store — Sample seed data (safe to run for local dev/testing)
-- =====================================================

USE ktex_db;

-- Admin account: sign up normally in the Flutter app (or Firebase Console)
-- with your admin email first, then find the firebase_uid in Firebase
-- Console -> Authentication -> Users, and run:
--   UPDATE users SET is_admin = 1 WHERE firebase_uid = 'PASTE_UID_HERE';
-- (the row is auto-created the first time that account calls the API)

INSERT INTO categories (name, image_url) VALUES
('Shirts', 'https://ktexstore.com/uploads/categories/shirts.jpg'),
('Kurtas', 'https://ktexstore.com/uploads/categories/kurtas.jpg'),
('Trousers', 'https://ktexstore.com/uploads/categories/trousers.jpg'),
('Accessories', 'https://ktexstore.com/uploads/categories/accessories.jpg')
ON DUPLICATE KEY UPDATE name = name;

INSERT INTO products (name, image_url, price, original_price, discount_percent, sold_label, is_premium, category_id, description, stock, is_flash_sale, is_new_arrival, is_for_you)
VALUES
('Premium Cotton Shirt', 'https://ktexstore.com/uploads/products/shirt1.jpg', 2499, 3499, 29, NULL, 1, 1, 'Premium quality cotton shirt, breathable fabric.', 40, 1, 0, 1),
('Classic Kurta', 'https://ktexstore.com/uploads/products/kurta1.jpg', 1899, NULL, NULL, '120 sold', 0, 2, 'Comfortable classic kurta for everyday wear.', 60, 0, 1, 1),
('Slim Fit Trousers', 'https://ktexstore.com/uploads/products/trouser1.jpg', 2199, 2799, 21, NULL, 0, 3, 'Slim fit formal trousers.', 35, 1, 0, 0),
('Leather Belt', 'https://ktexstore.com/uploads/products/belt1.jpg', 899, NULL, NULL, '80 sold', 0, 4, 'Genuine leather belt.', 100, 0, 1, 0)
ON DUPLICATE KEY UPDATE name = name;

INSERT INTO banners (title, subtitle, image_url, category, sort_order) VALUES
('New Season Arrivals', 'Fresh styles just landed', 'https://ktexstore.com/uploads/banners/banner1.jpg', 'Shirts', 1),
('Flash Sale', 'Up to 30% off', 'https://ktexstore.com/uploads/banners/banner2.jpg', NULL, 2)
ON DUPLICATE KEY UPDATE title = title;
