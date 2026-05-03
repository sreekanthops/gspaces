-- Add location/address field to leads table
ALTER TABLE leads ADD COLUMN IF NOT EXISTS location TEXT;

-- Add comment
COMMENT ON COLUMN leads.location IS 'Customer location/address for delivery and installation';

-- Made with Bob
