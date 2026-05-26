-- ============================================
-- Cost Analysis Feature - Admin Profit Calculator
-- ============================================
-- This script adds cost tracking for profit analysis

-- Add cost_price column to default_items table
ALTER TABLE default_items 
ADD COLUMN IF NOT EXISTS cost_price DECIMAL(10,2) DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN default_items.cost_price IS 'Actual cost price of item (for admin profit calculation)';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_default_items_cost_price ON default_items(cost_price);

-- Add cost_price to lead_designs for historical tracking
ALTER TABLE lead_designs
ADD COLUMN IF NOT EXISTS total_cost DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS profit_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(5,2) DEFAULT 0;

COMMENT ON COLUMN lead_designs.total_cost IS 'Total actual cost of all items in design';
COMMENT ON COLUMN lead_designs.profit_amount IS 'Profit amount (selling price - cost)';
COMMENT ON COLUMN lead_designs.profit_margin IS 'Profit margin percentage';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Cost Analysis feature schema created successfully!';
    RAISE NOTICE 'Added cost_price to default_items';
    RAISE NOTICE 'Added profit tracking columns to lead_designs';
END $$;

-- Made with Bob