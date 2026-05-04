-- Check custom_items column and data
SELECT 
    id,
    design_name,
    custom_items,
    pg_typeof(custom_items) as column_type
FROM lead_designs 
WHERE custom_items IS NOT NULL 
AND custom_items != '[]'::jsonb
LIMIT 5;

-- Also check the column definition
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'lead_designs' 
AND column_name = 'custom_items';

-- Made with Bob
