-- Add feedback columns to leads table for customer feedback on quotations
-- This allows customers to rate and provide feedback on their quotations

ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS customer_rating INTEGER CHECK (customer_rating >= 0 AND customer_rating <= 5),
ADD COLUMN IF NOT EXISTS customer_feedback TEXT,
ADD COLUMN IF NOT EXISTS feedback_submitted_at TIMESTAMP;

-- Create index for faster queries on feedback
CREATE INDEX IF NOT EXISTS idx_leads_feedback_submitted ON leads(feedback_submitted_at) WHERE feedback_submitted_at IS NOT NULL;

-- Add comment to document the columns
COMMENT ON COLUMN leads.customer_rating IS 'Customer rating for the quotation (1-5 stars)';
COMMENT ON COLUMN leads.customer_feedback IS 'Customer feedback or questions about the quotation';
COMMENT ON COLUMN leads.feedback_submitted_at IS 'Timestamp when customer submitted feedback';

-- Made with Bob
