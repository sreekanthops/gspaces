-- Add 'sizes' field to lead_designs table for studio/workspace dimensions
-- Examples: 10x12, 8x10, Custom Size, etc.

-- Add the sizes column
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS sizes VARCHAR(100);

-- Set default values for existing records
UPDATE lead_designs 
SET sizes = '10x12' 
WHERE sizes IS NULL AND type = 'Studio Setup';

UPDATE lead_designs 
SET sizes = 'Standard' 
WHERE sizes IS NULL AND type != 'Studio Setup';

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_lead_designs_sizes ON lead_designs(sizes);

-- Verify the changes
SELECT 
    id, 
    type,
    sizes,
    notes,
    created_at 
FROM lead_designs 
ORDER BY created_at DESC 
LIMIT 5;

-- Show distinct sizes
SELECT DISTINCT sizes, COUNT(*) as count
FROM lead_designs
WHERE sizes IS NOT NULL
GROUP BY sizes
ORDER BY count DESC;

-- Made with Bob
