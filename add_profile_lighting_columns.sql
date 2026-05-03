-- Add profile lighting columns to lead_designs table
-- This adds support for profile lighting as a separate item from rope lighting

ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS has_profile_lighting BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_lighting_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS profile_lighting_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS profile_lighting_details TEXT;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_lead_designs_profile_lighting ON lead_designs(has_profile_lighting) WHERE has_profile_lighting = TRUE;

COMMENT ON COLUMN lead_designs.has_profile_lighting IS 'Whether profile lighting is included in this design';
COMMENT ON COLUMN lead_designs.profile_lighting_quantity IS 'Quantity of profile lighting units';
COMMENT ON COLUMN lead_designs.profile_lighting_price IS 'Unit price for profile lighting';
COMMENT ON COLUMN lead_designs.profile_lighting_details IS 'Additional details about profile lighting';

-- Made with Bob