-- Fix Carousel: Remove all inactive images and ensure only 3 active images show
-- This will clean up the database to show only the carousel images you want

-- First, let's see what we have
SELECT 'Current Active Images:' as info;
SELECT id, title, is_active, display_order FROM homepage_carousel_images WHERE is_active = TRUE ORDER BY display_order;

-- Delete all inactive carousel images (they're just cluttering the database)
DELETE FROM homepage_carousel_images WHERE is_active = FALSE;

-- Reorder the active images to be 0, 1, 2
UPDATE homepage_carousel_images SET display_order = 0 WHERE id = 3;
UPDATE homepage_carousel_images SET display_order = 1 WHERE id = 5;
UPDATE homepage_carousel_images SET display_order = 2 WHERE id = 6;

-- Verify the cleanup
SELECT 'After Cleanup - Active Images:' as info;
SELECT id, title, is_active, display_order, image_url FROM homepage_carousel_images ORDER BY display_order;

-- Ensure carousel is enabled
UPDATE homepage_banner SET enable_carousel = TRUE WHERE id = 1;

SELECT 'Carousel Settings:' as info;
SELECT enable_carousel, slide_duration FROM homepage_banner WHERE is_active = TRUE;

-- Made with Bob
