-- Add 'type' field to lead_designs table for categorizing setup types
-- Examples: Work from Home Setup, Studio Setup, Office Setup, etc.

-- Add the type column
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS type VARCHAR(100);

-- Set default values for existing records
UPDATE lead_designs 
SET type = 'Office Setup' 
WHERE type IS NULL;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_lead_designs_type ON lead_designs(type);

-- Verify the changes
SELECT 
    id, 
    type,
    notes,
    created_at 
FROM lead_designs 
ORDER BY created_at DESC 
LIMIT 5;

-- Show distinct types
SELECT DISTINCT type, COUNT(*) as count
FROM lead_designs
WHERE type IS NOT NULL
GROUP BY type
ORDER BY count DESC;

-- Made with Bob
