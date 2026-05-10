-- Find Sai / GreenNest quotation media and exact paths to repair gallery records

-- 1) Find the Sai customer lead and share token
SELECT
    l.id AS lead_id,
    l.customer_name,
    l.project_name,
    l.share_token,
    l.reference_image,
    l.created_at
FROM leads l
WHERE l.customer_name ILIKE '%Sai%'
   OR l.project_name ILIKE '%GreenNest%'
ORDER BY l.created_at DESC;

-- 2) Find all designs under Sai / GreenNest leads with stored media fields
SELECT
    l.id AS lead_id,
    l.customer_name,
    l.project_name,
    ld.id AS lead_design_id,
    ld.design_name,
    ld.design_image,
    ld.media_files,
    ld.price,
    ld.final_price,
    ld.created_at
FROM leads l
JOIN lead_designs ld ON ld.lead_id = l.id
WHERE l.customer_name ILIKE '%Sai%'
   OR l.project_name ILIKE '%GreenNest%'
   OR ld.design_name ILIKE '%GreenNest%'
ORDER BY l.created_at DESC, ld.design_order, ld.id;

-- 3) Expand JSON media files for the matching designs
SELECT
    l.customer_name,
    l.project_name,
    ld.id AS lead_design_id,
    ld.design_name,
    media_item ->> 'type' AS media_type,
    media_item ->> 'url' AS media_url,
    media_item ->> 'thumbnail' AS thumbnail_url,
    media_item ->> 'order' AS media_order
FROM leads l
JOIN lead_designs ld ON ld.lead_id = l.id
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(ld.media_files, '[]'::jsonb)) AS media_item
WHERE l.customer_name ILIKE '%Sai%'
   OR l.project_name ILIKE '%GreenNest%'
   OR ld.design_name ILIKE '%GreenNest%'
ORDER BY ld.id, (media_item ->> 'order');

-- 4) Check what gallery currently points to for GreenNest
SELECT
    dg.id AS gallery_id,
    dg.title,
    dg.lead_design_id,
    dg.image_url,
    dg.category,
    di.id AS design_image_id,
    di.media_type,
    di.display_order,
    di.is_primary,
    di.image_url AS design_image_url,
    di.video_url AS design_video_url
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.title ILIKE '%GreenNest%'
   OR dg.lead_design_id IN (
       SELECT ld.id
       FROM leads l
       JOIN lead_designs ld ON ld.lead_id = l.id
       WHERE l.customer_name ILIKE '%Sai%'
          OR l.project_name ILIKE '%GreenNest%'
          OR ld.design_name ILIKE '%GreenNest%'
   )
ORDER BY dg.id, di.display_order, di.id;

-- 5) If step 3 returns the correct URL, use the returned values in updates like below:
-- UPDATE design_gallery
-- SET image_url = '/static/<correct-path-from-step-3>',
--     updated_at = CURRENT_TIMESTAMP
-- WHERE id = <gallery_id>;
--
-- UPDATE design_images
-- SET image_url = '/static/<correct-path-from-step-3>',
--     updated_at = CURRENT_TIMESTAMP
-- WHERE design_id = <gallery_id>
--   AND media_type = 'image'
--   AND is_primary = true;

-- Made with Bob
