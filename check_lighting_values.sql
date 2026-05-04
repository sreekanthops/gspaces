-- Check lighting length values in database
SELECT 
    id,
    design_name,
    has_lighting,
    lighting_quantity,
    lighting_length_ft,
    has_profile_lighting,
    profile_lighting_quantity,
    profile_lighting_length_ft
FROM lead_designs
WHERE has_lighting = TRUE OR has_profile_lighting = TRUE
ORDER BY id DESC
LIMIT 10;

-- Made with Bob
