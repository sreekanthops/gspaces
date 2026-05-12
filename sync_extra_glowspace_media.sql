-- Sync missing media files for Extra GlowSpace design
-- Design Gallery ID: 15, Lead Design ID: 24

-- First, let's see what we have
SELECT 'Current design_images for Extra GlowSpace:' as info;
SELECT id, design_id, image_url, video_url, media_type, is_primary 
FROM design_images 
WHERE design_id = 15;

-- Insert the missing media files
-- Media file 2: amaru_day.png
INSERT INTO design_images (design_id, image_url, media_type, display_order, is_primary)
VALUES (15, '/static/img/leads/media/design_24_2_20260512_185309_amaru_day.png', 'image', 2, false)
ON CONFLICT DO NOTHING;

-- Media file 3: amaru_collectios.mp4 (video)
INSERT INTO design_images (design_id, video_url, media_type, display_order, is_primary)
VALUES (15, '/static/img/leads/media/design_24_3_20260512_191334_amaru_collectios.mp4', 'video', 3, false)
ON CONFLICT DO NOTHING;

-- Verify the sync
SELECT 'After sync - design_images for Extra GlowSpace:' as info;
SELECT id, design_id, image_url, video_url, media_type, display_order, is_primary 
FROM design_images 
WHERE design_id = 15
ORDER BY display_order;

-- Show the count
SELECT 'Total media count:' as info, COUNT(*) as count 
FROM design_images 
WHERE design_id = 15;

-- Made with Bob
