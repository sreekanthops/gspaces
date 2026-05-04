-- Add missing items to default_items table
-- This ensures icons and descriptions are available for new fields

-- Multi Socket
INSERT INTO default_items (item_name, item_slug, icon_emoji, icon_image, default_price, description, display_order, is_active)
VALUES ('Multi Socket', 'multi_socket', '🔌', NULL, 500, 'Premium multi-socket power strip with surge protection and USB ports', 90, TRUE)
ON CONFLICT (item_slug) DO UPDATE SET
    description = EXCLUDED.description,
    default_price = EXCLUDED.default_price,
    icon_emoji = EXCLUDED.icon_emoji;

-- Desk Lamp
INSERT INTO default_items (item_name, item_slug, icon_emoji, icon_image, default_price, description, display_order, is_active)
VALUES ('Desk Lamp', 'desk_lamp', '💡', NULL, 800, 'LED desk lamp with adjustable brightness and color temperature', 91, TRUE)
ON CONFLICT (item_slug) DO UPDATE SET
    description = EXCLUDED.description,
    default_price = EXCLUDED.default_price,
    icon_emoji = EXCLUDED.icon_emoji;

-- Pen Holder
INSERT INTO default_items (item_name, item_slug, icon_emoji, icon_image, default_price, description, display_order, is_active)
VALUES ('Pen Holder', 'pen_holder', '✏️', NULL, 300, 'Wooden pen holder for organized desk storage', 92, TRUE)
ON CONFLICT (item_slug) DO UPDATE SET
    description = EXCLUDED.description,
    default_price = EXCLUDED.default_price,
    icon_emoji = EXCLUDED.icon_emoji;

-- Laptop Holder
INSERT INTO default_items (item_name, item_slug, icon_emoji, icon_image, default_price, description, display_order, is_active)
VALUES ('Laptop Holder', 'laptop_holder', '💻', NULL, 1200, 'Vertical laptop stand for space-saving desk organization', 93, TRUE)
ON CONFLICT (item_slug) DO UPDATE SET
    description = EXCLUDED.description,
    default_price = EXCLUDED.default_price,
    icon_emoji = EXCLUDED.icon_emoji;

-- Verify the items were added
SELECT item_name, item_slug, icon_emoji, default_price, description 
FROM default_items 
WHERE item_slug IN ('multi_socket', 'desk_lamp', 'pen_holder', 'laptop_holder')
ORDER BY display_order;

-- Made with Bob
