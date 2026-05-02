-- Rename deskmat columns to desk_mat to match code expectations
-- This fixes the column name mismatch

ALTER TABLE lead_designs RENAME COLUMN has_deskmat TO has_desk_mat;
ALTER TABLE lead_designs RENAME COLUMN deskmat_quantity TO desk_mat_quantity;
ALTER TABLE lead_designs RENAME COLUMN deskmat_price TO desk_mat_price;
ALTER TABLE lead_designs RENAME COLUMN deskmat_details TO desk_mat_details;

-- Verify the rename worked
SELECT 'Desk mat columns renamed successfully!' as status;
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'lead_designs' 
AND column_name LIKE '%desk_mat%';

-- Made with Bob
