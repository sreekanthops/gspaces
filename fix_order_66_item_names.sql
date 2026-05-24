-- Fix item names for order #66 to show simple names instead of descriptions

UPDATE order_items 
SET product_name = 'Fragrance Diffuser'
WHERE order_id = 66 AND product_name LIKE '%fragrance%';

UPDATE order_items 
SET product_name = 'Office Table'
WHERE order_id = 66 AND product_name LIKE '%table%';

UPDATE order_items 
SET product_name = 'Office Chair'
WHERE order_id = 66 AND product_name LIKE '%chair%';

UPDATE order_items 
SET product_name = 'Mini Plants'
WHERE order_id = 66 AND product_name LIKE '%plants%' AND product_name LIKE '%Compact%';

UPDATE order_items 
SET product_name = 'Photo Frames'
WHERE order_id = 66 AND product_name LIKE '%frames%';

UPDATE order_items 
SET product_name = 'Desk Lamp'
WHERE order_id = 66 AND product_name LIKE '%lamp%';

UPDATE order_items 
SET product_name = 'Pen Holder'
WHERE order_id = 66 AND product_name LIKE '%pen%';

-- Verify the changes
SELECT id, product_name, quantity, price_at_purchase 
FROM order_items 
WHERE order_id = 66
ORDER BY id;

-- Made with Bob
