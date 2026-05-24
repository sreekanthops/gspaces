-- Check default items table for icon paths
-- This will show us what icons are actually being used

-- First, show table structure
\d default_items

-- Check plant and chair items with their icons
SELECT
    item_slug,
    item_name,
    icon_image
FROM default_items
WHERE item_slug LIKE '%plant%' OR item_slug LIKE '%chair%'
ORDER BY item_slug;

-- Show all items to see the full list
SELECT
    item_slug,
    item_name,
    icon_image,
    default_price
FROM default_items
ORDER BY item_slug;

-- Made with Bob
