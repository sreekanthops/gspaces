-- Direct production repair for GreenNest Studio
-- Current live state confirmed:
--   design_gallery ids 2 and 14 still point to broken path
--   design_images for design_id = 14 is empty
-- This script fixes both gallery rows and recreates design_images rows.

BEGIN;

UPDATE design_gallery
SET image_url = '/static/img/leads/media/design_14_3_20260506_214952_daytime.png',
    category = 'studio',
    updated_at = CURRENT_TIMESTAMP
WHERE lead_design_id = 14
   OR title = 'GreenNest Studio';

DELETE FROM design_images
WHERE design_id = 14;

INSERT INTO design_images (
    design_id, image_url, video_url, media_type, display_order, is_primary, created_at
) VALUES
    (14, '/static/img/leads/media/design_14_3_20260506_214952_daytime.png', NULL, 'image', 0, true, CURRENT_TIMESTAMP),
    (14, '/static/img/leads/media/design_14_2_20260506_195832_nightview.png', NULL, 'image', 1, false, CURRENT_TIMESTAMP),
    (14, NULL, '/static/img/leads/media/design_14_2_20260506_204630_sai_manikonda.mp4', 'video', 2, false, CURRENT_TIMESTAMP);

COMMIT;

SELECT id, title, lead_design_id, category, image_url
FROM design_gallery
WHERE lead_design_id = 14
   OR title = 'GreenNest Studio'
ORDER BY id;

SELECT design_id, media_type, display_order, is_primary, image_url, video_url
FROM design_images
WHERE design_id = 14
ORDER BY display_order, is_primary DESC;

-- Made with Bob
