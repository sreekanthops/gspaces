-- =====================================================
-- Animated Banner Fix - EC2 Deployment Queries
-- Run these queries on your EC2 PostgreSQL database
-- =====================================================

-- 1. Fix image paths for existing furniture items
UPDATE animated_furniture_items 
SET image_path = 'images/furniture/chair.png', 
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

UPDATE animated_furniture_items 
SET image_path = 'images/furniture/desk.png',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 2;

-- 2. Disable furniture items with missing images
UPDATE animated_furniture_items 
SET is_active = false,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 9;

-- 3. Verify the changes
SELECT id, name, category, image_path, is_active, width, height, initial_x, initial_y
FROM animated_furniture_items
WHERE id IN (1, 2, 9)
ORDER BY id;

-- 4. Check all active furniture items
SELECT id, name, category, image_path, is_active, display_order
FROM animated_furniture_items
WHERE is_active = true
ORDER BY display_order ASC;

-- 5. Verify banner settings are enabled
SELECT * FROM animated_banner_settings LIMIT 1;

-- 6. Count active items
SELECT 
    COUNT(*) as total_items,
    COUNT(CASE WHEN is_active THEN 1 END) as active_items,
    COUNT(CASE WHEN NOT is_active THEN 1 END) as inactive_items
FROM animated_furniture_items;

-- =====================================================
-- Expected Results:
-- - 2 active furniture items (Chair and Desk)
-- - Correct image paths without /static/ prefix
-- - Banner settings enabled with is_enabled = true
-- =====================================================

-- Made with Bob
