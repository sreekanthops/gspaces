-- Add type and sizes fields to leads table for initial setup information
-- These will be copied to lead_designs when designs are created

ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS setup_type VARCHAR(100),
ADD COLUMN IF NOT EXISTS space_size VARCHAR(100);

COMMENT ON COLUMN leads.setup_type IS 'Type of workspace setup (e.g., Work from Home, Studio Setup)';
COMMENT ON COLUMN leads.space_size IS 'Space dimensions or size category (e.g., 4x8 ft, Small, Medium)';

-- Show the updated structure
SELECT column_name, data_type, character_maximum_length 
FROM information_schema.columns 
WHERE table_name = 'leads' 
AND column_name IN ('setup_type', 'space_size');

-- Made with Bob
