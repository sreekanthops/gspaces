-- Add new category "Individual" for individual items (tables, chairs, pen holders, etc.)
-- Position it as the first category after "All" (before Basic, Couple, Greenery, etc.)

DO $$
BEGIN
    -- First, shift all existing categories down by 1 to make room
    -- This assumes "All" is at position 0 or 1, and we want "Individual" at position 1
    UPDATE categories 
    SET display_order = display_order + 1 
    WHERE display_order >= 1;
    
    -- Insert the new "Individual" category at position 1
    INSERT INTO categories (name, slug, display_order, is_active, created_at, updated_at)
    VALUES (
        'Individual',
        'individual',
        1,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (name) DO NOTHING;
END $$;

-- Verify the category order
SELECT id, name, slug, display_order, is_active 
FROM categories 
ORDER BY display_order ASC;

-- Made with Bob
