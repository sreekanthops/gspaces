-- Create default_items table to store all available lead items
-- This allows dynamic management of items instead of hardcoded fields

CREATE TABLE IF NOT EXISTS default_items (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL UNIQUE,
    item_slug VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(10) DEFAULT '📦',
    default_price DECIMAL(10,2) DEFAULT 0,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert existing 18 items with their current icons and default prices
INSERT INTO default_items (item_name, item_slug, icon, default_price, display_order, is_active) VALUES
('Desk Table', 'table', '🪑', 18000, 1, TRUE),
('Chair', 'chair', '🪑', 10000, 2, TRUE),
('Plants', 'plants', '🌿', 500, 3, TRUE),
('Rope Lighting', 'lighting', '💡', 500, 4, TRUE),
('Profile Lighting', 'profile_lighting', '💡', 800, 5, TRUE),
('Storage', 'storage', '🗄️', 5000, 6, TRUE),
('Accessories', 'accessories', '🎨', 2000, 7, TRUE),
('Big Plants', 'big_plants', '🌳', 1500, 8, TRUE),
('Mini Plants', 'mini_plants', '🪴', 300, 9, TRUE),
('Frames', 'frames', '🖼️', 500, 10, TRUE),
('Wall Racks', 'wall_racks', '📚', 2000, 11, TRUE),
('Desk Mat', 'desk_mat', '🎯', 800, 12, TRUE),
('Dustbin', 'dustbin', '🗑️', 300, 13, TRUE),
('Floor Mat', 'floor_mat', '🧹', 1000, 14, TRUE),
('Keyboard', 'keyboard', '⌨️', 2000, 15, TRUE),
('Mouse', 'mouse', '🖱️', 800, 16, TRUE),
('Paint', 'paint', '🎨', 5000, 17, TRUE),
('Wardrobes', 'wardrobes', '🚪', 1000, 18, TRUE)
ON CONFLICT (item_slug) DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_default_items_slug ON default_items(item_slug);
CREATE INDEX IF NOT EXISTS idx_default_items_active ON default_items(is_active);
CREATE INDEX IF NOT EXISTS idx_default_items_order ON default_items(display_order);

COMMENT ON TABLE default_items IS 'Stores all available items that can be added to lead designs';
COMMENT ON COLUMN default_items.item_slug IS 'URL-friendly identifier used in code';
COMMENT ON COLUMN default_items.icon IS 'Emoji or icon to display';
COMMENT ON COLUMN default_items.display_order IS 'Order in which items appear in UI';

-- Made with Bob
