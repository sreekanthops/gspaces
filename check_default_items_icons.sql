-- Check default items table for icon paths
-- This will show us what icons are actually being used

-- Check if table exists and show all items with their icons
SELECT 
    item_slug,
    item_name,
    icon_image,
    category
FROM default_items
WHERE item_slug LIKE '%plant%' OR item_slug LIKE '%chair%'
ORDER BY category, item_slug;

-- Show all items to see the full list
SELECT 
    item_slug,
    item_name,
    icon_image,
    category,
    default_price
FROM default_items
ORDER BY category, item_slug;

-- Made with Bob
