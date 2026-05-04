-- Debug script to check lighting length issue
-- Run this to see what's actually stored in the database

-- 1. Check if columns exist
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'lead_designs'
AND column_name IN ('lighting_length_ft', 'profile_lighting_length_ft')
ORDER BY column_name;

-- 2. Check actual values in the most recent designs
SELECT 
    id,
    lead_id,
    design_name,
    has_lighting,
    lighting_quantity,
    lighting_length_ft,
    has_profile_lighting,
    profile_lighting_quantity,
    profile_lighting_length_ft,
    created_at
FROM lead_designs
ORDER BY id DESC
LIMIT 5;

-- 3. Check if any designs have non-default values
SELECT 
    COUNT(*) as total_designs,
    COUNT(CASE WHEN lighting_length_ft IS NOT NULL AND lighting_length_ft != 10 THEN 1 END) as custom_lighting_length,
    COUNT(CASE WHEN profile_lighting_length_ft IS NOT NULL AND profile_lighting_length_ft != 10 THEN 1 END) as custom_profile_length
FROM lead_designs;

-- Made with Bob
