-- Add 'delivered' to the lead_status check constraint
-- This allows leads to have lead_status = 'delivered'

-- Drop the old constraint
ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_lead_status_check;

-- Add new constraint with 'delivered' included
ALTER TABLE leads ADD CONSTRAINT leads_lead_status_check 
CHECK (lead_status IN ('customer', 'lead', 'reminder', 'delivered'));

-- Verify the constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'leads_lead_status_check';

-- Made with Bob