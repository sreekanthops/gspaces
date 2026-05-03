-- Enhanced default_items table with icon upload support
-- This replaces the basic default_items table with full CRUD capabilities

-- Drop existing table if needed (backup data first in production!)
-- DROP TABLE IF EXISTS default_items CASCADE;

CREATE TABLE IF NOT EXISTS default_items (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL UNIQUE,
    item_slug VARCHAR(100) NOT NULL UNIQUE,
    icon_emoji VARCHAR(10) DEFAULT '📦',
    icon_image VARCHAR(500), -- Path to uploaded icon image
    default_price DECIMAL(10,2) DEFAULT 0,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert existing items with their current icons and default prices
INSERT INTO default_items (item_name, item_slug, icon_emoji, default_price, description, display_order, is_active) VALUES
('Desk Table', 'table', '🪑', 18000, 'Standard ergonomic desk table', 1, TRUE),
('Chair', 'chair', '💺', 10000, 'Ergonomic office chair with lumbar support', 2, TRUE),
('Plants', 'plants', '🌿', 500, 'Indoor plants for decoration', 3, TRUE),
('Rope Lighting', 'lighting', '💡', 500, 'LED rope/ambient lighting per sq ft', 4, TRUE),
('Profile Lighting', 'profile_lighting', '💡', 800, 'Profile/accent lighting', 5, TRUE),
('Storage', 'storage', '🗄️', 5000, 'Cabinets, drawers, and shelves', 6, TRUE),
('Accessories', 'accessories', '🎨', 2000, 'Desk organizers and accessories', 7, TRUE),
('Big Plants', 'big_plants', '🌳', 1500, 'Large indoor plants per plant', 8, TRUE),
('Mini Plants', 'mini_plants', '🪴', 300, 'Small desktop plants per plant', 9, TRUE),
('Frames', 'frames', '🖼️', 500, 'Wall art frames per frame', 10, TRUE),
('Wall Racks', 'wall_racks', '📚', 2000, 'Wall-mounted racks per rack', 11, TRUE),
('Desk Mat', 'desk_mat', '🎯', 800, 'Large desk pad/mat', 12, TRUE),
('Dustbin', 'dustbin', '🗑️', 300, 'Desktop/floor waste bin', 13, TRUE),
('Floor Mat', 'floor_mat', '🧹', 1000, 'Floor carpet/mat per sq ft', 14, TRUE),
('Keyboard', 'keyboard', '⌨️', 2000, 'Mechanical/wireless keyboard', 15, TRUE),
('Mouse', 'mouse', '🖱️', 800, 'Wireless/ergonomic mouse', 16, TRUE),
('Paint', 'paint', '🎨', 5000, 'Wall painting', 17, TRUE),
('Wardrobes', 'wardrobes', '🚪', 1000, 'Storage wardrobes per sq ft', 18, TRUE),
('Desk Lamp', 'desk_lamp', '💡', 2500, 'LED desk lamp', 19, TRUE),
('Pen Holder', 'pen_holder', '✏️', 500, 'Desktop pen/pencil holder', 20, TRUE),
('Laptop Holder', 'laptop_holder', '💻', 1800, 'Vertical laptop stand', 21, TRUE),
('Monitor', 'monitor', '🖥️', 15000, 'LED/LCD display monitor', 22, TRUE),
('Laptop Stand', 'laptop_stand', '💻', 2000, 'Adjustable laptop riser', 23, TRUE),
('Cable Management', 'cable_management', '🔌', 800, 'Cable organizers and clips', 24, TRUE),
('Footrest', 'footrest', '🦶', 1500, 'Ergonomic footrest', 25, TRUE),
('Headphone Stand', 'headphone_stand', '🎧', 800, 'Desktop headphone holder', 26, TRUE),
('Whiteboard', 'whiteboard', '📝', 3500, 'Wall-mounted whiteboard', 27, TRUE),
('Bookshelf', 'bookshelf', '📚', 10000, 'Wall/floor bookshelf', 28, TRUE),
('Monitor Stand', 'monitor_stand', '🖥️', 2500, 'Adjustable monitor riser', 29, TRUE),
('Desk Organizer', 'desk_organizer', '📋', 1500, 'Desktop organization system', 30, TRUE)
ON CONFLICT (item_slug) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    icon_emoji = EXCLUDED.icon_emoji,
    default_price = EXCLUDED.default_price,
    description = EXCLUDED.description,
    display_order = EXCLUDED.display_order,
    updated_at = CURRENT_TIMESTAMP;

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_default_items_slug ON default_items(item_slug);
CREATE INDEX IF NOT EXISTS idx_default_items_active ON default_items(is_active);
CREATE INDEX IF NOT EXISTS idx_default_items_order ON default_items(display_order);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_default_items_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_default_items_updated_at ON default_items;
CREATE TRIGGER update_default_items_updated_at 
    BEFORE UPDATE ON default_items
    FOR EACH ROW 
    EXECUTE FUNCTION update_default_items_timestamp();

-- Comments
COMMENT ON TABLE default_items IS 'Master table for all available items that can be added to lead designs';
COMMENT ON COLUMN default_items.item_slug IS 'URL-friendly identifier used in code';
COMMENT ON COLUMN default_items.icon_emoji IS 'Emoji icon to display (fallback if no image)';
COMMENT ON COLUMN default_items.icon_image IS 'Path to uploaded icon image file';
COMMENT ON COLUMN default_items.display_order IS 'Order in which items appear in UI';
COMMENT ON COLUMN default_items.is_active IS 'Whether item is available for selection';

-- Made with Bob