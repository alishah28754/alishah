-- =====================================================
-- KTEX Store — MySQL Schema
-- Matches the Flutter app models exactly:
--   models.dart (Product, BannerSlide)
--   cart_model.dart (CartItem)
--   favourites_model.dart
--   order_model.dart (Order, OrderItem)
--   checkout_screen.dart (name, email, phone, address, city, zip, payment)
-- =====================================================

CREATE DATABASE IF NOT EXISTS ktex_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ktex_db;

-- -----------------------------------------------------
-- USERS
-- Auth is handled entirely by Firebase (Google + email/password) on the
-- Flutter app. This table just mirrors the profile locally so we can
-- attach orders/cart/favourites/is_admin to a normal MySQL foreign key.
-- Rows are auto-created by the backend the first time a Firebase user's
-- ID token is verified (see src/middleware/auth.js).
-- -----------------------------------------------------
-- password_hash is only set for admin-panel accounts (bcrypt hash, checked by
-- POST /api/auth/admin-login). Regular shopper rows keep it NULL and log in
-- via Firebase as before. firebase_uid is nullable so an admin-only row
-- (created purely to log into the admin panel) doesn't need one.
CREATE TABLE IF NOT EXISTS users (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  firebase_uid      VARCHAR(128)  NULL UNIQUE,
  name              VARCHAR(150)  NOT NULL,
  email             VARCHAR(191)  NULL UNIQUE,
  phone             VARCHAR(30)   NULL,
  provider          VARCHAR(20)   NOT NULL DEFAULT 'email',   -- 'email' | 'google'
  profile_image     VARCHAR(500)  NULL,
  is_email_verified TINYINT(1)    NOT NULL DEFAULT 0,
  password_hash     VARCHAR(255)  NULL,
  is_admin          TINYINT(1)    NOT NULL DEFAULT 0,
  is_active         TINYINT(1)    NOT NULL DEFAULT 1,
  login_count       INT UNSIGNED  NOT NULL DEFAULT 0,
  last_login        TIMESTAMP     NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- CATEGORIES
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(150)  NOT NULL,
  parent_category   ENUM('Men','Women','Kids') NOT NULL DEFAULT 'Men',
  image_url         VARCHAR(500)  NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categories_name_parent (name, parent_category),
  INDEX idx_categories_parent (parent_category)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PRODUCTS  (maps 1:1 to lib/models/models.dart -> Product)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(255)  NOT NULL,
  image_url         VARCHAR(500)  NOT NULL,
  price             INT UNSIGNED  NOT NULL,
  original_price    INT UNSIGNED  NULL,        -- for flash sales
  discount_percent  INT UNSIGNED  NULL,        -- for flash sales
  sold_label        VARCHAR(100)  NULL,        -- e.g. "120 sold" (new arrivals / for-you)
  is_premium        TINYINT(1)    NOT NULL DEFAULT 0,
  category_id       INT UNSIGNED  NULL,
  description       TEXT          NULL,
  stock             INT UNSIGNED  NOT NULL DEFAULT 0,
  is_flash_sale     TINYINT(1)    NOT NULL DEFAULT 0,
  is_new_arrival    TINYINT(1)    NOT NULL DEFAULT 0,
  is_for_you        TINYINT(1)    NOT NULL DEFAULT 0,
  metadata          JSON          NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL,
  INDEX idx_products_category (category_id),
  INDEX idx_products_flash_sale (is_flash_sale),
  INDEX idx_products_new_arrival (is_new_arrival),
  INDEX idx_products_for_you (is_for_you)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- BANNERS  (maps to models.dart -> BannerSlide)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS banners (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(255)  NOT NULL,
  subtitle      VARCHAR(255)  NULL,
  image_url     VARCHAR(500)  NOT NULL,
  category      VARCHAR(150)  NULL,   -- links banner CTA to a category
  sort_order    INT           NOT NULL DEFAULT 0,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- CART ITEMS  (maps to cart_model.dart -> CartItem, persisted per user)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS cart_items (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED  NOT NULL,
  product_id    INT UNSIGNED  NOT NULL,
  quantity      INT UNSIGNED  NOT NULL DEFAULT 1,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cart_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_user_product (user_id, product_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- FAVOURITES  (maps to favourites_model.dart)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS favourites (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED  NOT NULL,
  product_id    INT UNSIGNED  NOT NULL,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fav_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_fav_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE KEY uniq_user_fav_product (user_id, product_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ORDERS  (maps to order_model.dart -> Order, + checkout_screen.dart fields)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number      VARCHAR(40)   NOT NULL UNIQUE,   -- e.g. KTEX-20260806-0001
  user_id           INT UNSIGNED  NULL,               -- NULL allowed for guest checkout
  customer_name     VARCHAR(150)  NOT NULL,
  email             VARCHAR(191)  NOT NULL,
  phone             VARCHAR(30)   NOT NULL,
  address           VARCHAR(500)  NOT NULL,
  city              VARCHAR(100)  NOT NULL,
  zip               VARCHAR(20)   NULL,
  payment_method    ENUM('cod','payfast','easypaisa','jazzcash','bank') NOT NULL DEFAULT 'cod',
  transaction_id    VARCHAR(100)  NULL,
  transaction_screenshot_url VARCHAR(500) NULL,  -- payment proof uploaded by shopper at checkout
  payfast_txn_id    VARCHAR(100)  NULL,
  subtotal          INT UNSIGNED  NOT NULL,
  total             INT UNSIGNED  NOT NULL,
  status            ENUM('Processing','Confirmed','Shipped','Delivered','Cancelled')
                    NOT NULL DEFAULT 'Processing',
  tracking_number   VARCHAR(100)  NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_orders_user (user_id),
  INDEX idx_orders_status (status)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ORDER ITEMS (maps to order_model.dart -> OrderItem)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id      INT UNSIGNED  NOT NULL,
  product_id    INT UNSIGNED  NULL,
  name          VARCHAR(255)  NOT NULL,
  price         INT UNSIGNED  NOT NULL,
  quantity      INT UNSIGNED  NOT NULL DEFAULT 1,
  image_url     VARCHAR(500)  NULL,
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
  INDEX idx_order_items_order (order_id)
) ENGINE=InnoDB;
