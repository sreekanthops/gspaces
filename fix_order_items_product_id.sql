-- ============================================
-- Fix order_items table to allow NULL product_id
-- ============================================
-- For admin-created orders from quotations, product_id may not exist

-- Make product_id nullable
ALTER TABLE order_items 
ALTER COLUMN product_id DROP NOT NULL;

-- Add comment
COMMENT ON COLUMN order_items.product_id IS 'Product ID - nullable for admin-created orders from quotations';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ order_items.product_id is now nullable';
    RAISE NOTICE 'Admin-created orders can now be saved without product_id';
END $$;

-- Made with Bob
