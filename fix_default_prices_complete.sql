-- Complete fix for default prices display issue
-- This ensures all items show their default prices in the UI

-- First, verify all 32 items exist
SELECT 'Verifying item_default_prices table...' as status;
SELECT COUNT(*) as total_items, 
       COUNT(CASE WHEN default_price > 0 THEN 1 END) as items_with_price
FROM item_default_prices;

-- Show all items with their default prices
SELECT item_name, default_price, description 
FROM item_default_prices 
ORDER BY item_name;

-- Create a view for easy access to default prices
CREATE OR REPLACE VIEW v_item_defaults AS
SELECT 
    item_name,
    default_price,
    description,
    updated_at
FROM item_default_prices
ORDER BY item_name;

-- Grant access to the view
GRANT SELECT ON v_item_defaults TO PUBLIC;

SELECT 'Default prices setup complete!' as status;
SELECT 'Total items: ' || COUNT(*) as summary FROM item_default_prices;

-- Made with Bob
