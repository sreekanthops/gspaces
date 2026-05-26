-- ============================================
-- Add Advance Payment and Delivery Date Support
-- ============================================
-- This script adds columns to support advance payments and delivery dates

-- Add new columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS advance_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS pending_amount DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS expected_delivery_date DATE;

-- Add comments for documentation
COMMENT ON COLUMN orders.advance_amount IS 'Advance amount paid by customer';
COMMENT ON COLUMN orders.pending_amount IS 'Pending amount to be paid (calculated: total_amount - advance_amount)';
COMMENT ON COLUMN orders.expected_delivery_date IS 'Expected delivery date for the order';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_expected_delivery_date ON orders(expected_delivery_date);

-- Update existing orders to have default values
UPDATE orders 
SET advance_amount = 0,
    pending_amount = total_amount
WHERE advance_amount IS NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Advance payment and delivery date columns added successfully!';
    RAISE NOTICE 'New columns: advance_amount, pending_amount, expected_delivery_date';
END $$;

-- Made with Bob