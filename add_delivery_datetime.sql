-- Add delivery_date and delivery_time columns to orders table
-- This allows admin to specify when an order was actually delivered

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS delivery_date DATE,
ADD COLUMN IF NOT EXISTS delivery_time TIME;

-- Add comment for documentation
COMMENT ON COLUMN orders.delivery_date IS 'Actual date when order was delivered to customer';
COMMENT ON COLUMN orders.delivery_time IS 'Actual time when order was delivered to customer';

-- Create index for faster queries on delivery_date
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(delivery_date);

-- Made with Bob
