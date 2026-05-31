-- Fix orders that have admin email instead of customer email
-- This updates orders to use customer_email from the leads table

UPDATE orders o
SET user_email = COALESCE(
    l.customer_email,
    o.customer_name || '@customer.gspaces.in'
)
FROM leads l
WHERE o.quotation_id = l.id
  AND o.order_source = 'quotation_order'
  AND (o.user_email LIKE '%@gmail.com' OR o.user_email LIKE '%admin%');

-- Show updated orders
SELECT 
    o.id,
    o.customer_name,
    o.user_email as updated_email,
    l.customer_email as lead_email
FROM orders o
LEFT JOIN leads l ON o.quotation_id = l.id
WHERE o.order_source = 'quotation_order'
ORDER BY o.id DESC
LIMIT 20;

-- Made with Bob
