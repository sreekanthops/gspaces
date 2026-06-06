-- Rename "Couple" category to "Gaming"
-- This updates both the category name and slug

-- Update the category name and slug
UPDATE categories 
SET name = 'Gaming', 
    slug = 'gaming',
    updated_at = CURRENT_TIMESTAMP
WHERE name = 'Couple';

-- Update all products that use the "Couple" category
UPDATE products 
SET category = 'Gaming',
    updated_at = CURRENT_TIMESTAMP
WHERE category = 'Couple';

-- Verify the changes
SELECT id, name, slug, display_order, is_active 
FROM categories 
WHERE name = 'Gaming';

-- Check how many products were updated
SELECT COUNT(*) as gaming_products 
FROM products 
WHERE category = 'Gaming';

-- Made with Bob
