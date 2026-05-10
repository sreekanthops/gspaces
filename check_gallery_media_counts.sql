-- Check why current gallery cards are not showing image-count badges / multiple images

-- 1) Show all gallery rows with linked lead design and media count
SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.lead_design_id,
    dg.image_url,
    dg.is_active,
    COUNT(di.id) AS media_count,
    SUM(CASE WHEN di.media_type = 'image' THEN 1 ELSE 0 END) AS image_rows,
    SUM(CASE WHEN di.media_type = 'video' THEN 1 ELSE 0 END) AS video_rows
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
GROUP BY dg.id, dg.title, dg.lead_design_id, dg.image_url, dg.is_active
ORDER BY dg.id;

-- 2) Show lead designs that have media_files with more than 1 item
SELECT
    ld.id AS lead_design_id,
    ld.design_name,
    ld.design_image,
    jsonb_array_length(COALESCE(ld.media_files, '[]'::jsonb)) AS media_file_count,
    ld.media_files
FROM lead_designs ld
WHERE jsonb_array_length(COALESCE(ld.media_files, '[]'::jsonb)) > 1
ORDER BY ld.id;

-- 3) Show current design_images rows for gallery entries linked to those lead designs
SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.lead_design_id,
    di.id AS design_image_id,
    di.media_type,
    di.display_order,
    di.is_primary,
    di.image_url,
    di.video_url
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.lead_design_id IN (
    SELECT ld.id
    FROM lead_designs ld
    WHERE jsonb_array_length(COALESCE(ld.media_files, '[]'::jsonb)) > 1
)
ORDER BY dg.id, di.display_order, di.id;

-- 4) Focus on active public gallery rows only
SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.lead_design_id,
    dg.image_url,
    COUNT(di.id) AS media_count
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.is_active = TRUE
GROUP BY dg.id, dg.title, dg.lead_design_id, dg.image_url
ORDER BY dg.id;

-- Made with Bob
