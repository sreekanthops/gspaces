-- Clean up ALL existing categories and start fresh with only 7 categories

-- First, remove the foreign key constraint temporarily to allow deletion
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_category_id_fkey;

-- Delete ALL existing categories
DELETE FROM categories;

-- Reset the sequence
ALTER SEQUENCE categories_id_seq RESTART WITH 1;

-- Insert ONLY the 7 new categories in correct order
INSERT INTO categories (name, slug, display_order, is_active) VALUES
('Basic', 'basic', 1, TRUE),
('Storage', 'storage', 2, TRUE),
('Elegant', 'elegant', 3, TRUE),
('Greenery', 'greenery', 4, TRUE),
('Couple', 'couple', 5, TRUE),
('Luxury', 'luxury', 6, TRUE),
('Studio', 'studio', 7, TRUE);

-- Re-add the foreign key constraint
ALTER TABLE products 
ADD CONSTRAINT products_category_id_fkey 
FOREIGN KEY (category_id) REFERENCES categories(id);

-- Set all existing products to NULL category_id (admin will need to reassign)
UPDATE products SET category_id = NULL;

-- Show the final categories
SELECT id, name, slug, display_order, is_active FROM categories ORDER BY display_order;

-- Made with Bob
