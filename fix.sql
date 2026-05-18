-- Fix pricing for "Extra GlowSpace" design by linking it to a lead design
-- Option 1: Link to lead_design_id 24 (₹92,720)
-- Option 2: Link to lead_design_id 16 (₹82,460) - same as original GlowSpace

-- Check current status
SELECT 
    dg.id, 
    dg.title, 
    dg.lead_design_id, 
    ld.price as quoted_price 
FROM design_gallery dg 
LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id 
WHERE dg.title = 'Extra GlowSpace';

-- Update to link to lead_design_id 24 (higher price variant)
UPDATE design_gallery 
SET lead_design_id = 24,
    updated_at = NOW()
WHERE id = 15 AND title = 'Extra GlowSpace';

-- Verify the update
SELECT 
    dg.id, 
    dg.title, 
    dg.lead_design_id, 
    ld.price as quoted_price 
FROM design_gallery dg 
LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id 
WHERE dg.title = 'Extra GlowSpace';

-- If you prefer to link to the same price as original GlowSpace (₹82,460), use this instead:
-- UPDATE design_gallery 
-- SET lead_design_id = 16,
--     updated_at = NOW()
-- WHERE id = 15 AND title = 'Extra GlowSpace';

-- Made with Bob
