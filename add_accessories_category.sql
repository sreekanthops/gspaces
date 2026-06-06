-- Add new category for individual items (tables, chairs, pen holders, etc.)
-- This category is for standalone accessories and furniture pieces

-- Get the next display_order value
DO $$
DECLARE
    next_order INTEGER;
BEGIN
    SELECT COALESCE(MAX(display_order), 0) + 1 INTO next_order FROM categories;
    
    INSERT INTO categories (name, slug, display_order, is_active, created_at, updated_at)
    VALUES (
        'Accessories',
        'accessories',
        next_order,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (name) DO NOTHING;
END $$;

-- Verify the category was added
SELECT id, name, slug, display_order, is_active FROM categories WHERE name = 'Accessories';

-- Made with Bob
