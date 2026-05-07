-- Add quotation expiry columns to leads table
-- Default validity is 7 days from creation date

ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS valid_until TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_expired BOOLEAN DEFAULT FALSE;

-- Set valid_until for existing leads (7 days from created_at)
UPDATE leads 
SET valid_until = created_at + INTERVAL '7 days'
WHERE valid_until IS NULL;

-- Create index for faster expiry checks
CREATE INDEX IF NOT EXISTS idx_leads_valid_until ON leads(valid_until);
CREATE INDEX IF NOT EXISTS idx_leads_is_expired ON leads(is_expired);

-- Add comment for documentation
COMMENT ON COLUMN leads.valid_until IS 'Quotation expiry date/time - default 7 days from creation';
COMMENT ON COLUMN leads.is_expired IS 'Flag to mark quotation as expired - can be manually set by admin';

-- Made with Bob
