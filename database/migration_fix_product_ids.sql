-- =====================================================
-- KTEX Store — FIX: Product ID Type Mismatch
-- Converts product IDs from INT to VARCHAR(50) to match
-- frontend string IDs like "cat-new-001", "prem-001"
-- Run this FIRST before starting the backend
-- =====================================================

USE ktex_db;

-- Step 1: Drop foreign key constraints
ALTER TABLE order_items DROP FOREIGN KEY IF EXISTS fk_order_items_product;
ALTER TABLE cart_items DROP FOREIGN KEY IF EXISTS fk_cart_product;
ALTER TABLE favourites DROP FOREIGN KEY IF EXISTS fk_fav_product;

-- Step 2: Modify child tables to accept string product IDs
ALTER TABLE order_items MODIFY product_id VARCHAR(50) NULL;
ALTER TABLE cart_items MODIFY product_id VARCHAR(50) NOT NULL;
ALTER TABLE favourites MODIFY product_id VARCHAR(50) NOT NULL;

-- Step 3: Convert products table to use string IDs
ALTER TABLE products MODIFY id VARCHAR(50) NOT NULL;
ALTER TABLE products DROP PRIMARY KEY, ADD PRIMARY KEY (id);

-- Step 4: Re-add foreign key constraints
ALTER TABLE order_items 
  ADD CONSTRAINT fk_order_items_product 
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;

ALTER TABLE cart_items 
  ADD CONSTRAINT fk_cart_product 
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

ALTER TABLE favourites 
  ADD CONSTRAINT fk_fav_product 
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

-- Step 5: Update existing numeric IDs to string format (if you have data)
UPDATE products SET id = CONCAT('prod-', id) WHERE id NOT LIKE '%-%';

-- Step 6: Verify the changes
SHOW CREATE TABLE products;
SHOW CREATE TABLE order_items;
SHOW CREATE TABLE cart_items;
SHOW CREATE TABLE favourites;