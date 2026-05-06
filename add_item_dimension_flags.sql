-- Add persistent dimension configuration to default_items
-- and ensure custom_items can store dimension values in JSON.

ALTER TABLE default_items
ADD COLUMN IF NOT EXISTS has_length BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_breadth BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_height BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN default_items.has_length IS 'Whether this item should capture a length dimension';
COMMENT ON COLUMN default_items.has_breadth IS 'Whether this item should capture a breadth/width dimension';
COMMENT ON COLUMN default_items.has_height IS 'Whether this item should capture a height dimension';

-- Suggested defaults for common size-based items
UPDATE default_items
SET has_length = TRUE, has_breadth = TRUE, has_height = TRUE
WHERE item_slug IN ('table', 'storage', 'wardrobes');

UPDATE default_items
SET has_length = TRUE, has_breadth = TRUE, has_height = FALSE
WHERE item_slug IN ('desk_mat');

UPDATE default_items
SET has_length = TRUE, has_breadth = FALSE, has_height = FALSE
WHERE item_slug IN ('lighting', 'profile_lighting', 'wall_racks');

UPDATE default_items
SET has_length = FALSE, has_breadth = FALSE, has_height = TRUE
WHERE item_slug IN ('big_plants', 'mini_plants');

-- Frames currently use a size string; keep flags disabled unless migrated later.

SELECT item_slug, has_length, has_breadth, has_height
FROM default_items
ORDER BY display_order, item_name;

-- Made with Bob
