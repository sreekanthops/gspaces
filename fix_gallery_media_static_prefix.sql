-- Fix broken detail-page media caused by missing /static/ prefix in design_images rows

BEGIN;

UPDATE design_images
SET image_url = CASE
    WHEN image_url IS NOT NULL
         AND image_url != ''
         AND image_url NOT LIKE '/static/%'
    THEN '/static/' || image_url
    ELSE image_url
END,
video_url = CASE
    WHEN video_url IS NOT NULL
         AND video_url != ''
         AND video_url NOT LIKE '/static/%'
    THEN '/static/' || video_url
    ELSE video_url
END,
thumbnail_url = CASE
    WHEN thumbnail_url IS NOT NULL
         AND thumbnail_url != ''
         AND thumbnail_url NOT LIKE '/static/%'
    THEN '/static/' || thumbnail_url
    ELSE thumbnail_url
END
WHERE
    (image_url IS NOT NULL AND image_url != '' AND image_url NOT LIKE '/static/%')
    OR (video_url IS NOT NULL AND video_url != '' AND video_url NOT LIKE '/static/%')
    OR (thumbnail_url IS NOT NULL AND thumbnail_url != '' AND thumbnail_url NOT LIKE '/static/%');

COMMIT;

SELECT
    id,
    design_id,
    media_type,
    image_url,
    video_url,
    thumbnail_url
FROM design_images
ORDER BY design_id, is_primary DESC, display_order, id;

-- Made with Bob
