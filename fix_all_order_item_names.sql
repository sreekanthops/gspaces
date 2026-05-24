-- Fix item names for ALL orders to show simple names instead of descriptions
-- This updates the order_items table for all existing orders

-- Fragrance items
UPDATE order_items 
SET product_name = 'Fragrance Diffuser'
WHERE product_name LIKE '%fragrance%' OR product_name LIKE '%diffuser%';

-- Table items
UPDATE order_items 
SET product_name = 'Office Table'
WHERE (product_name LIKE '%table%' OR product_name LIKE '%desk%') 
  AND product_name NOT LIKE '%lamp%'
  AND product_name NOT LIKE '%mat%';

-- Chair items
UPDATE order_items 
SET product_name = 'Office Chair'
WHERE product_name LIKE '%chair%' AND product_name NOT LIKE '%headrest%';

-- Plants items
UPDATE order_items 
SET product_name = 'Mini Plants'
WHERE (product_name LIKE '%plants%' OR product_name LIKE '%Succulent%' OR product_name LIKE '%Cacti%')
  AND (product_name LIKE '%mini%' OR product_name LIKE '%Compact%' OR product_name LIKE '%desk plant%');

UPDATE order_items 
SET product_name = 'Big Plants'
WHERE product_name LIKE '%plants%' AND product_name LIKE '%big%';

UPDATE order_items 
SET product_name = 'Plants'
WHERE product_name LIKE '%plants%' AND product_name NOT IN ('Mini Plants', 'Big Plants');

-- Frames
UPDATE order_items 
SET product_name = 'Photo Frames'
WHERE product_name LIKE '%frame%' OR product_name LIKE '%photo%';

-- Desk Lamp
UPDATE order_items 
SET product_name = 'Desk Lamp'
WHERE product_name LIKE '%lamp%' AND product_name LIKE '%desk%';

UPDATE order_items 
SET product_name = 'Floor Lamp'
WHERE product_name LIKE '%lamp%' AND product_name LIKE '%floor%';

-- Pen Holder
UPDATE order_items 
SET product_name = 'Pen Holder'
WHERE product_name LIKE '%pen%' AND product_name LIKE '%holder%';

-- Wall Racks
UPDATE order_items 
SET product_name = 'Wall Racks'
WHERE product_name LIKE '%wall%' AND product_name LIKE '%rack%';

-- Desk Mat
UPDATE order_items 
SET product_name = 'Desk Mat'
WHERE product_name LIKE '%desk%' AND product_name LIKE '%mat%';

-- Floor Mat
UPDATE order_items 
SET product_name = 'Floor Mat'
WHERE product_name LIKE '%floor%' AND product_name LIKE '%mat%';

-- Dustbin
UPDATE order_items 
SET product_name = 'Dustbin'
WHERE product_name LIKE '%dustbin%' OR product_name LIKE '%trash%' OR product_name LIKE '%bin%';

-- Keyboard
UPDATE order_items 
SET product_name = 'Keyboard'
WHERE product_name LIKE '%keyboard%';

-- Mouse
UPDATE order_items 
SET product_name = 'Mouse'
WHERE product_name LIKE '%mouse%';

-- Curtains
UPDATE order_items 
SET product_name = 'Curtains'
WHERE product_name LIKE '%curtain%';

-- Monitor
UPDATE order_items 
SET product_name = 'Monitor'
WHERE product_name LIKE '%monitor%' AND product_name NOT LIKE '%stand%';

-- Monitor Stand
UPDATE order_items 
SET product_name = 'Monitor Stand'
WHERE product_name LIKE '%monitor%' AND product_name LIKE '%stand%';

-- Laptop Stand
UPDATE order_items 
SET product_name = 'Laptop Stand'
WHERE product_name LIKE '%laptop%' AND product_name LIKE '%stand%';

-- Laptop Holder
UPDATE order_items 
SET product_name = 'Laptop Holder'
WHERE product_name LIKE '%laptop%' AND product_name LIKE '%holder%';

-- Headphone Stand
UPDATE order_items 
SET product_name = 'Headphone Stand'
WHERE product_name LIKE '%headphone%';

-- Lighting
UPDATE order_items 
SET product_name = 'Track Light'
WHERE product_name LIKE '%track%' AND product_name LIKE '%light%';

UPDATE order_items 
SET product_name = 'Neon Light'
WHERE product_name LIKE '%neon%';

UPDATE order_items 
SET product_name = 'Profile Lighting'
WHERE product_name LIKE '%profile%' AND product_name LIKE '%light%';

UPDATE order_items 
SET product_name = 'Lighting'
WHERE product_name LIKE '%light%' 
  AND product_name NOT IN ('Desk Lamp', 'Floor Lamp', 'Track Light', 'Neon Light', 'Profile Lighting');

-- Storage
UPDATE order_items 
SET product_name = 'Storage'
WHERE product_name LIKE '%storage%';

UPDATE order_items 
SET product_name = 'Wardrobes'
WHERE product_name LIKE '%wardrobe%';

UPDATE order_items 
SET product_name = 'Bookshelf'
WHERE product_name LIKE '%bookshelf%' OR product_name LIKE '%book shelf%';

-- Accessories
UPDATE order_items 
SET product_name = 'Desk Organizer'
WHERE product_name LIKE '%organizer%';

UPDATE order_items 
SET product_name = 'Cable Management'
WHERE product_name LIKE '%cable%';

UPDATE order_items 
SET product_name = 'Footrest'
WHERE product_name LIKE '%footrest%' OR product_name LIKE '%foot rest%';

UPDATE order_items 
SET product_name = 'Whiteboard'
WHERE product_name LIKE '%whiteboard%' OR product_name LIKE '%white board%';

UPDATE order_items 
SET product_name = 'Wall Art'
WHERE product_name LIKE '%wall art%';

UPDATE order_items 
SET product_name = 'Multi Socket'
WHERE product_name LIKE '%socket%' OR product_name LIKE '%extension%';

UPDATE order_items 
SET product_name = 'Carpet'
WHERE product_name LIKE '%carpet%';

UPDATE order_items 
SET product_name = 'Paint'
WHERE product_name LIKE '%paint%';

UPDATE order_items 
SET product_name = 'Accessories'
WHERE product_name LIKE '%accessor%' 
  AND product_name NOT IN ('Desk Organizer', 'Cable Management', 'Footrest', 'Whiteboard', 'Wall Art', 'Multi Socket', 'Carpet', 'Paint');

-- Show summary of changes
SELECT 
    product_name, 
    COUNT(*) as count,
    SUM(quantity) as total_quantity
FROM order_items 
GROUP BY product_name
ORDER BY count DESC;

-- Made with Bob
