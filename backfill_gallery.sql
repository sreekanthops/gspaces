-- Backfill design_images for all auto-synced gallery rows from lead_designs.media_files
-- Root cause found: only gallery_id 14 has design_images rows; others with media_files > 1 were never backfilled.

BEGIN;

-- Clear existing synced gallery media rows so they can be rebuilt cleanly
DELETE FROM design_images
WHERE design_id IN (
    SELECT id
    FROM design_gallery
    WHERE auto_synced = true
      AND lead_design_id IS NOT NULL
);

-- Rebuild media rows from lead_designs.media_files
WITH gallery_source AS (
    SELECT
        dg.id AS gallery_id,
        ld.id AS lead_design_id,
        COALESCE(
            (
                SELECT media_item ->> 'url'
                FROM jsonb_array_elements(COALESCE(ld.media_files, '[]'::jsonb)) AS media_item
                WHERE COALESCE(media_item ->> 'type', 'image') = 'image'
                ORDER BY COALESCE(NULLIF(media_item ->> 'order', '')::INTEGER, 0)
                LIMIT 1
            ),
            ld.design_image
        ) AS first_image_url,
        ld.media_files,
        ld.design_image
    FROM design_gallery dg
    JOIN lead_designs ld ON ld.id = dg.lead_design_id
    WHERE dg.auto_synced = true
      AND dg.lead_design_id IS NOT NULL
),
media_rows AS (
    SELECT
        gs.gallery_id,
        gs.first_image_url,
        media_item,
        COALESCE(media_item ->> 'type', 'image') AS media_type,
        media_item ->> 'url' AS media_url,
        COALESCE(NULLIF(media_item ->> 'order', '')::INTEGER, 0) AS media_order
    FROM gallery_source gs
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(gs.media_files, '[]'::jsonb)) AS media_item
),
inserted_media AS (
    INSERT INTO design_images (
        design_id,
        image_url,
        video_url,
        media_type,
        display_order,
        is_primary
    )
    SELECT
        mr.gallery_id,
        CASE
            WHEN mr.media_type = 'video' THEN mr.first_image_url
            ELSE mr.media_url
        END AS image_url,
        CASE
            WHEN mr.media_type = 'video' THEN mr.media_url
            ELSE NULL
        END AS video_url,
        mr.media_type,
        mr.media_order,
        (mr.media_type = 'image' AND mr.media_url = mr.first_image_url) AS is_primary
    FROM media_rows mr
    WHERE mr.media_url IS NOT NULL
      AND mr.media_url != ''
    RETURNING design_id
)
SELECT COUNT(*) AS inserted_rows
FROM inserted_media;

-- For synced gallery rows with no media_files, ensure at least one primary image row exists
INSERT INTO design_images (
    design_id,
    image_url,
    video_url,
    media_type,
    display_order,
    is_primary
)
SELECT
    dg.id,
    CASE
        WHEN ld.design_image LIKE '/static/%' THEN ld.design_image
        ELSE '/static/' || ld.design_image
    END AS image_url,
    NULL AS video_url,
    'image' AS media_type,
    0 AS display_order,
    true AS is_primary
FROM design_gallery dg
JOIN lead_designs ld ON ld.id = dg.lead_design_id
WHERE dg.auto_synced = true
  AND dg.lead_design_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM design_images di
      WHERE di.design_id = dg.id
  )
  AND ld.design_image IS NOT NULL
  AND ld.design_image != '';

-- Update gallery primary image to first image from media_files when available
UPDATE design_gallery dg
SET image_url = src.first_image_url,
    updated_at = CURRENT_TIMESTAMP
FROM (
    SELECT
        dg_inner.id AS gallery_id,
        COALESCE(
            (
                SELECT CASE
                    WHEN (media_item ->> 'url') LIKE '/static/%' THEN media_item ->> 'url'
                    ELSE '/static/' || (media_item ->> 'url')
                END
                FROM jsonb_array_elements(COALESCE(ld.media_files, '[]'::jsonb)) AS media_item
                WHERE COALESCE(media_item ->> 'type', 'image') = 'image'
                ORDER BY COALESCE(NULLIF(media_item ->> 'order', '')::INTEGER, 0)
                LIMIT 1
            ),
            CASE
                WHEN ld.design_image LIKE '/static/%' THEN ld.design_image
                ELSE '/static/' || ld.design_image
            END
        ) AS first_image_url
    FROM design_gallery dg_inner
    JOIN lead_designs ld ON ld.id = dg_inner.lead_design_id
    WHERE dg_inner.auto_synced = true
      AND dg_inner.lead_design_id IS NOT NULL
) src
WHERE dg.id = src.gallery_id
  AND src.first_image_url IS NOT NULL;

COMMIT;

-- Verify current counts after backfill
SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.lead_design_id,
    COUNT(di.id) AS media_count,
    SUM(CASE WHEN di.media_type = 'image' THEN 1 ELSE 0 END) AS image_rows,
    SUM(CASE WHEN di.media_type = 'video' THEN 1 ELSE 0 END) AS video_rows
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.is_active = TRUE
GROUP BY dg.id, dg.title, dg.lead_design_id
ORDER BY dg.id;

-- Made with Bob
