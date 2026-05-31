-- Fix existing leads that were moved to delivered section
-- but don't have lead_status set to 'delivered'

UPDATE leads 
SET lead_status = 'delivered'
WHERE lead_section = 'delivered' 
  AND lead_status != 'delivered';

-- Show how many were updated
SELECT COUNT(*) as fixed_leads 
FROM leads 
WHERE lead_section = 'delivered' 
  AND lead_status = 'delivered';

-- Made with Bob