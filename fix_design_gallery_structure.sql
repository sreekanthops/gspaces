-- Fix design gallery structure to have one design per lead design
-- with multiple images in design_images table

-- 1. Create a temporary table to store current designs
CREATE TABLE IF NOT EXISTS temp_design_gallery AS
SELECT * FROM design_gallery;

-- 2. Clear current design_gallery and design_images
TRUNCATE TABLE design_gallery;
TRUNCATE TABLE design_images;

-- 3. For each lead design, create one design entry
-- and add all images to design_images table
INSERT INTO design_gallery (
    id, title, description, image_url, display_order,
    category, lead_design_id, auto_synced, is_active, created_at, updated_at
)
SELECT
    ld.id,
    ld.design_name,
    'Auto-synced from customer lead',
    (SELECT design_image FROM lead_designs WHERE id = ld.id LIMIT 1),
    ld.design_order,
    COALESCE(l.design_category, 'office'),
    ld.id,
    true,
    true,  -- Activate all designs
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM lead_designs ld
LEFT JOIN leads l ON ld.lead_id = l.id
WHERE ld.design_image IS NOT NULL AND ld.design_image != ''
ORDER BY ld.created_at DESC;

-- 4. For each design, add all images to design_images table
-- (In this case, we only have one image per lead design for now)
INSERT INTO design_images (
    design_id, image_url, display_order, is_primary, created_at
)
SELECT
    ld.id,
    ld.design_image,
    0,
    true,  -- Mark as primary
    CURRENT_TIMESTAMP
FROM lead_designs ld
WHERE ld.design_image IS NOT NULL AND ld.design_image != ''
ORDER BY ld.created_at DESC;

-- 5. Update image URLs to include /static prefix
UPDATE design_gallery SET image_url = '/static/' || image_url
WHERE image_url NOT LIKE '/static%';

UPDATE design_images SET image_url = '/static/' || image_url
WHERE image_url NOT LIKE '/static%';

-- 6. Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Design gallery structure fixed!';
    RAISE NOTICE '✅ One design entry per lead design';
    RAISE NOTICE '✅ All images in design_images table';
    RAISE NOTICE '✅ Primary images marked';
    RAISE NOTICE '✅ All designs activated';
END $$;

-- Made with Bob
