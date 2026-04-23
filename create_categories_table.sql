-- Create categories table for dynamic category management
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert existing categories first (preserve current data)
INSERT INTO categories (name, slug, display_order, is_active) VALUES
('Ergonomic', 'ergonomic', 1, TRUE),
('Minimalist', 'minimalist', 2, TRUE),
('Executive', 'executive', 3, TRUE)
ON CONFLICT (name) DO NOTHING;

-- Add new categories
INSERT INTO categories (name, slug, display_order, is_active) VALUES
('Greenery', 'greenery', 4, TRUE),
('Couple Studio', 'couple-studio', 5, TRUE),
('Basic Storage', 'basic-storage', 6, TRUE),
('Elegant', 'elegant', 7, TRUE),
('Luxury Studio', 'luxury-studio', 8, TRUE)
ON CONFLICT (name) DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_order ON categories(display_order);

-- Add foreign key to products table (if not exists)
-- First, let's check if products table has category as text
DO $$ 
BEGIN
    -- Add category_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='products' AND column_name='category_id') THEN
        ALTER TABLE products ADD COLUMN category_id INTEGER REFERENCES categories(id);
    END IF;
END $$;

-- Migrate existing product categories to category_id
UPDATE products p
SET category_id = c.id
FROM categories c
WHERE p.category = c.name AND p.category_id IS NULL;

-- Create index on products.category_id
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);

COMMENT ON TABLE categories IS 'Dynamic product categories managed by admin';
COMMENT ON COLUMN categories.display_order IS 'Order in which categories appear in navigation (lower = first)';
COMMENT ON COLUMN categories.is_active IS 'Whether category is visible to users';

-- Made with Bob
