-- Add individual item prices and discount fields to lead_designs table

-- Add price fields for each item
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS table_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS chair_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS plants_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS lighting_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS storage_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS accessories_price DECIMAL(10,2) DEFAULT 0;

-- Add discount fields
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS discount_type VARCHAR(20) DEFAULT 'none', -- 'none', 'percentage', 'fixed'
ADD COLUMN IF NOT EXISTS discount_value DECIMAL(10,2) DEFAULT 0;

-- Add calculated total field (will be computed in application)
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS final_price DECIMAL(10,2) DEFAULT 0;

-- Update custom_items structure to include price
-- Custom items will store: {"name": "Item", "details": "Desc", "icon": "🔧", "price": 1000}

COMMENT ON COLUMN lead_designs.table_price IS 'Price for desk/table item';
COMMENT ON COLUMN lead_designs.chair_price IS 'Price for chair item';
COMMENT ON COLUMN lead_designs.plants_price IS 'Price for plants & decor item';
COMMENT ON COLUMN lead_designs.lighting_price IS 'Price for lighting item';
COMMENT ON COLUMN lead_designs.storage_price IS 'Price for storage solutions item';
COMMENT ON COLUMN lead_designs.accessories_price IS 'Price for accessories item';
COMMENT ON COLUMN lead_designs.discount_type IS 'Type of discount: none, percentage, or fixed';
COMMENT ON COLUMN lead_designs.discount_value IS 'Discount value (percentage or fixed amount)';
COMMENT ON COLUMN lead_designs.subtotal IS 'Total before discount';
COMMENT ON COLUMN lead_designs.final_price IS 'Final price after discount';

-- Made with Bob
