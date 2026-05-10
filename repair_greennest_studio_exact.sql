-- Exact repair for Sai -> GreenNest Studio gallery records
-- Based on verified query output from production

BEGIN;

-- There are currently two gallery rows pointing to the same lead_design_id = 14:
--   gallery_id = 2   category = office
--   gallery_id = 14  category = studio
-- Both point to a missing image:
--   /static/img/leads/media/media_20260506_192614_0_daytime.png
--
-- Verified valid quotation media paths:
--   /static/img/leads/media/design_14_2_20260506_195832_nightview.png
--   /static/img/leads/media/design_14_2_20260506_204630_sai_manikonda.mp4
--   /static/img/leads/media/design_14_3_20260506_214952_daytime.png

-- Prefer the latest daytime image as primary gallery image
UPDATE design_gallery
SET image_url = '/static/img/leads/media/design_14_3_20260506_214952_daytime.png',
    updated_at = CURRENT_TIMESTAMP
WHERE lead_design_id = 14
  AND title = 'GreenNest Studio';

-- Rebuild gallery media rows for the canonical gallery record (id = 14)
DELETE FROM design_images
WHERE design_id = 14;

INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary, created_at)
VALUES
    (14, '/static/img/leads/media/design_14_3_20260506_214952_daytime.png', NULL, 'image', 0, true, CURRENT_TIMESTAMP),
    (14, '/static/img/leads/media/design_14_2_20260506_195832_nightview.png', NULL, 'image', 1, false, CURRENT_TIMESTAMP),
    (14, NULL, '/static/img/leads/media/design_14_2_20260506_204630_sai_manikonda.mp4', 'video', 2, false, CURRENT_TIMESTAMP);

-- Optional but recommended:
-- remove duplicate gallery row id = 2 so only one GreenNest Studio card appears
DELETE FROM design_gallery
WHERE id = 2
  AND lead_design_id = 14
  AND title = 'GreenNest Studio';

COMMIT;

-- Verify final state
SELECT id, title, lead_design_id, category, image_url
FROM design_gallery
WHERE lead_design_id = 14
ORDER BY id;

SELECT design_id, media_type, display_order, is_primary, image_url, video_url
FROM design_images
WHERE design_id = 14
ORDER BY display_order, is_primary DESC;

-- Made with Bob
