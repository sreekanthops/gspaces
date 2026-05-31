-- Add delivery_description column to orders table
-- This allows admin to specify what was delivered (e.g., "Studio Setup", "Study Unit")

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS delivery_description VARCHAR(255);

-- Add comment for documentation
COMMENT ON COLUMN orders.delivery_description IS 'Description of what was delivered (e.g., Studio Setup, Study Unit) - shown in email header';

-- Made with Bob