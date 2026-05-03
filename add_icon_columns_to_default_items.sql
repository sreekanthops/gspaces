-- Add icon_emoji and icon_image columns to default_items table
-- This allows storing both emoji and uploaded image icons

ALTER TABLE default_items 
ADD COLUMN IF NOT EXISTS icon_emoji VARCHAR(10) DEFAULT '📦',
ADD COLUMN IF NOT EXISTS icon_image VARCHAR(255),
ADD COLUMN IF NOT EXISTS description TEXT;

-- Migrate existing icon data to icon_emoji
UPDATE default_items SET icon_emoji = icon WHERE icon_emoji IS NULL;

-- Update description for existing items
UPDATE default_items SET description = 
    CASE item_slug
        WHEN 'table' THEN 'Ergonomic desk table with storage options'
        WHEN 'chair' THEN 'Comfortable office chair with lumbar support'
        WHEN 'plants' THEN 'Decorative indoor plants'
        WHEN 'lighting' THEN 'LED rope lighting for ambiance'
        WHEN 'profile_lighting' THEN 'Profile/accent lighting'
        WHEN 'storage' THEN 'Storage cabinets and organizers'
        WHEN 'accessories' THEN 'Desk accessories and decor'
        WHEN 'big_plants' THEN 'Large decorative plants'
        WHEN 'mini_plants' THEN 'Small desk plants'
        WHEN 'frames' THEN 'Wall frames and artwork'
        WHEN 'wall_racks' THEN 'Wall-mounted storage racks'
        WHEN 'desk_mat' THEN 'Desk mat for workspace'
        WHEN 'dustbin' THEN 'Waste bin'
        WHEN 'floor_mat' THEN 'Floor mat for workspace'
        WHEN 'keyboard' THEN 'Mechanical keyboard'
        WHEN 'mouse' THEN 'Ergonomic mouse'
        WHEN 'paint' THEN 'Wall paint and finishing'
        WHEN 'wardrobes' THEN 'Storage wardrobes'
        ELSE 'No description available'
    END
WHERE description IS NULL;

-- Create index for icon_image lookups
CREATE INDEX IF NOT EXISTS idx_default_items_icon_image ON default_items(icon_image) WHERE icon_image IS NOT NULL;

COMMENT ON COLUMN default_items.icon_emoji IS 'Emoji icon displayed if no image uploaded';
COMMENT ON COLUMN default_items.icon_image IS 'Path to uploaded icon image (relative to static folder)';
COMMENT ON COLUMN default_items.description IS 'Item description for admin reference';

-- Made with Bob
