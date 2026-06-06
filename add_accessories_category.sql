-- Add new category for individual items (tables, chairs, pen holders, etc.)
-- This category is for standalone accessories and furniture pieces

INSERT INTO categories (name, description, created_at, updated_at)
VALUES (
    'Accessories',
    'Individual furniture items and accessories - tables, chairs, pen holders, desk organizers, and more',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (name) DO NOTHING;

-- Verify the category was added
SELECT id, name, description FROM categories WHERE name = 'Accessories';

-- Made with Bob
