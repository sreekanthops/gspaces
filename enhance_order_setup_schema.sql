-- ============================================
-- Order Setup Enhancement - Database Schema
-- ============================================
-- Adds quotation integration and enhanced order details

-- Add quotation link and enhanced fields to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS quotation_id INTEGER REFERENCES leads(id),
ADD COLUMN IF NOT EXISTS design_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS design_image VARCHAR(500),
ADD COLUMN IF NOT EXISTS original_price NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS items_json JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS measurements_json JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS delivery_address TEXT;

-- Add comments for documentation
COMMENT ON COLUMN orders.quotation_id IS 'Link to the quotation/lead that generated this order';
COMMENT ON COLUMN orders.design_name IS 'Name of the design from quotation';
COMMENT ON COLUMN orders.design_image IS 'Primary image of the design';
COMMENT ON COLUMN orders.original_price IS 'Original price before discount';
COMMENT ON COLUMN orders.discount_percentage IS 'Discount percentage applied';
COMMENT ON COLUMN orders.items_json IS 'JSON array of all items from quotation with quantities and prices';
COMMENT ON COLUMN orders.measurements_json IS 'JSON object with measurements and specifications';
COMMENT ON COLUMN orders.delivery_address IS 'Full delivery address from quotation';

-- Create index for quotation lookup
CREATE INDEX IF NOT EXISTS idx_orders_quotation_id ON orders(quotation_id);

-- Add order_created flag to leads table to track if order was created
ALTER TABLE leads 
ADD COLUMN IF NOT EXISTS order_created BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS order_id INTEGER,
ADD COLUMN IF NOT EXISTS order_created_at TIMESTAMP;

COMMENT ON COLUMN leads.order_created IS 'Flag indicating if an order was created from this quotation';
COMMENT ON COLUMN leads.order_id IS 'ID of the order created from this quotation';
COMMENT ON COLUMN leads.order_created_at IS 'Timestamp when order was created';

-- Create index for order lookup from leads
CREATE INDEX IF NOT EXISTS idx_leads_order_id ON leads(order_id);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Order Setup Enhancement schema created successfully!';
    RAISE NOTICE 'Added quotation integration fields to orders table';
    RAISE NOTICE 'Added order tracking fields to leads table';
    RAISE NOTICE 'Created necessary indexes';
END $$;

-- Made with Bob
