-- Add customer type and priority fields to leads table

ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS customer_type VARCHAR(20) DEFAULT 'genuine',
ADD COLUMN IF NOT EXISTS is_priority BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN leads.customer_type IS 'Type of customer: genuine or casual';
COMMENT ON COLUMN leads.is_priority IS 'Star/priority flag for active follow-up';

-- Show the updated structure
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'leads' 
AND column_name IN ('customer_type', 'is_priority');

-- Made with Bob
