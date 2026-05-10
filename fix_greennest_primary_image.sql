-- Fix GreenNest Studio broken first image by forcing the valid daytime image as primary/main image

BEGIN;

-- Fix gallery card/main image for both duplicate GreenNest rows
UPDATE design_gallery
SET image_url = '/static/img/leads/media/design_14_3_20260506_214952_daytime.png',
    updated_at = CURRENT_TIMESTAMP
WHERE lead_design_id = 14;

-- Remove broken/old media rows for GreenNest
DELETE FROM design_images
WHERE design_id IN (
    SELECT id FROM design_gallery WHERE lead_design_id = 14
);

-- Reinsert valid ordered media for both GreenNest gallery rows
INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary)
SELECT
    dg.id,
    '/static/img/leads/media/design_14_3_20260506_214952_daytime.png',
    NULL,
    'image',
    0,
    true
FROM design_gallery dg
WHERE dg.lead_design_id = 14;

INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary)
SELECT
    dg.id,
    '/static/img/leads/media/design_14_2_20260506_195832_nightview.png',
    NULL,
    'image',
    1,
    false
FROM design_gallery dg
WHERE dg.lead_design_id = 14;

INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary)
SELECT
    dg.id,
    '/static/img/leads/media/design_14_3_20260506_214952_daytime.png',
    '/static/img/leads/media/design_14_2_20260506_204630_sai_manikonda.mp4',
    'video',
    2,
    false
FROM design_gallery dg
WHERE dg.lead_design_id = 14;

COMMIT;

SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.image_url AS gallery_image_url,
    di.id AS design_image_id,
    di.media_type,
    di.display_order,
    di.is_primary,
    di.image_url,
    di.video_url
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.lead_design_id = 14
ORDER BY dg.id, di.display_order, di.id;

-- Made with Bob
