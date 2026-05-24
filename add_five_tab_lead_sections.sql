-- Add 5-tab lead section support and richer reminder tracking
-- Tabs: star, confirmed, delivered, reminders, leads

ALTER TABLE leads
ADD COLUMN IF NOT EXISTS lead_section VARCHAR(20);

UPDATE leads
SET lead_section = CASE
    WHEN lead_section IS NOT NULL THEN lead_section
    WHEN COALESCE(is_priority, FALSE) = TRUE THEN 'star'
    WHEN lead_status = 'customer' THEN 'confirmed'
    WHEN lead_status = 'reminder' THEN 'reminders'
    ELSE 'leads'
END;

ALTER TABLE leads
ALTER COLUMN lead_section SET DEFAULT 'leads';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'leads_lead_section_check'
    ) THEN
        ALTER TABLE leads
        ADD CONSTRAINT leads_lead_section_check
        CHECK (lead_section IN ('star', 'confirmed', 'delivered', 'reminders', 'leads'));
    END IF;
END $$;

ALTER TABLE leads
ADD COLUMN IF NOT EXISTS reminder_comment TEXT,
ADD COLUMN IF NOT EXISTS reminder_last_notified_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS reminder_completed BOOLEAN DEFAULT FALSE;

UPDATE leads
SET reminder_comment = COALESCE(reminder_comment, reminder_notes)
WHERE reminder_comment IS NULL;

CREATE INDEX IF NOT EXISTS idx_leads_lead_section ON leads(lead_section);
CREATE INDEX IF NOT EXISTS idx_leads_reminder_active
ON leads(lead_section, reminder_date)
WHERE lead_section = 'reminders';

COMMENT ON COLUMN leads.lead_section IS 'Admin pipeline tab: star, confirmed, delivered, reminders, leads';
COMMENT ON COLUMN leads.reminder_comment IS 'Reminder note/comment shown in admin notifications';
COMMENT ON COLUMN leads.reminder_last_notified_at IS 'Last time an in-app reminder notification was issued';
COMMENT ON COLUMN leads.reminder_completed IS 'Whether reminder follow-up has been completed';

-- Keep old values aligned where possible
UPDATE leads
SET is_priority = (lead_section = 'star');

-- Made with Bob