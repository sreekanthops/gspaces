-- Manually sync existing lead designs to gallery
-- Run this once to sync all existing lead designs that have images

INSERT INTO design_gallery (
    title,
    description,
    image_url,
    display_order,
    category,
    lead_design_id,
    auto_synced,
    is_active
)
SELECT 
    ld.design_name,
    'Auto-synced from customer lead',
    '/' || ld.design_image,  -- Add leading slash for proper path
    ld.design_order,
    'office',  -- default category
    ld.id,
    true,
    false  -- Start as inactive for admin review
FROM lead_designs ld
WHERE ld.design_image IS NOT NULL 
  AND ld.design_image != ''
  AND NOT EXISTS (
    SELECT 1 FROM design_gallery dg 
    WHERE dg.lead_design_id = ld.id
  )
ORDER BY ld.created_at DESC;

-- Show what was synced
SELECT 
    id,
    title,
    image_url,
    is_active,
    lead_design_id
FROM design_gallery
WHERE auto_synced = true
ORDER BY created_at DESC;

-- Success message
DO $$
DECLARE
    synced_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO synced_count
    FROM design_gallery
    WHERE auto_synced = true;
    
    RAISE NOTICE '✅ Synced % lead designs to gallery!', synced_count;
    RAISE NOTICE 'All designs are INACTIVE - go to Admin Panel to review and activate them.';
END $$;

-- Made with Bob
