-- Fix broken GreenNest Studio gallery media paths
-- Verified existing file:
--   /static/img/leads/media/design_13_2_20260506_192513_daytime.png
-- Missing old paths:
--   /static/img/leads/media/media_20260506_192614_0_daytime.png
--   /static/img/leads/media/media_20260506_192614_1_studio_view.png
--   /static/img/leads/media/media_20260506_192614_2_studio_walkthrough.mp4

BEGIN;

-- Update primary gallery image
UPDATE design_gallery
SET image_url = '/static/img/leads/media/design_13_2_20260506_192513_daytime.png',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 14
  AND title = 'GreenNest Studio';

-- Update primary design image entry
UPDATE design_images
SET image_url = '/static/img/leads/media/design_13_2_20260506_192513_daytime.png',
    updated_at = CURRENT_TIMESTAMP
WHERE design_id = 14
  AND media_type = 'image'
  AND display_order = 0;

-- Optional cleanup: remove broken extra image/video rows for this design
DELETE FROM design_images
WHERE design_id = 14
  AND (
    image_url IN (
      '/static/img/leads/media/media_20260506_192614_0_daytime.png',
      '/static/img/leads/media/media_20260506_192614_1_studio_view.png'
    )
    OR video_url = '/static/img/leads/media/media_20260506_192614_2_studio_walkthrough.mp4'
  )
  AND NOT (
    media_type = 'image'
    AND display_order = 0
    AND image_url = '/static/img/leads/media/design_13_2_20260506_192513_daytime.png'
  );

COMMIT;

-- Verify
SELECT id, title, image_url
FROM design_gallery
WHERE id = 14;

SELECT design_id, media_type, display_order, image_url, video_url, is_primary
FROM design_images
WHERE design_id = 14
ORDER BY display_order, is_primary DESC;

-- Made with Bob
