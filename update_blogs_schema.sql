-- Update blog schema to remove approval system and add product reference
-- Run this after migrate_blogs_to_reactions.sql

-- Add product_id column
ALTER TABLE customer_blogs ADD COLUMN IF NOT EXISTS product_id INTEGER REFERENCES products(id) ON DELETE SET NULL;

-- Remove approval-related columns
ALTER TABLE customer_blogs DROP COLUMN IF EXISTS status;
ALTER TABLE customer_blogs DROP COLUMN IF EXISTS approved_at;
ALTER TABLE customer_blogs DROP COLUMN IF EXISTS approved_by;

-- Add index for product_id
CREATE INDEX IF NOT EXISTS idx_blogs_product_id ON customer_blogs(product_id);

SELECT 'Blog schema updated successfully!' as status;

-- Made with Bob
