-- Add lead_status and reminder_date columns to leads table
-- This allows categorizing leads into: customers, leads, reminders

-- Add lead_status column with default 'lead' for all existing leads
ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS lead_status VARCHAR(20) DEFAULT 'lead' 
CHECK (lead_status IN ('customer', 'lead', 'reminder'));

-- Add reminder_date column for tracking follow-up dates
ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS reminder_date TIMESTAMP;

-- Add reminder_notes column for reminder-specific notes
ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS reminder_notes TEXT;

-- Create index for better performance when filtering by status
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(lead_status);

-- Create index for reminder dates
CREATE INDEX IF NOT EXISTS idx_leads_reminder_date ON leads(reminder_date);

-- Update all existing leads to have 'lead' status if NULL
UPDATE leads SET lead_status = 'lead' WHERE lead_status IS NULL;

-- Add comment to explain the column
COMMENT ON COLUMN leads.lead_status IS 'Lead categorization: customer (serious buyer), lead (potential), reminder (follow-up needed)';
COMMENT ON COLUMN leads.reminder_date IS 'Date/time when to follow up with this lead';
COMMENT ON COLUMN leads.reminder_notes IS 'Notes about what to discuss during reminder follow-up';

-- Made with Bob
