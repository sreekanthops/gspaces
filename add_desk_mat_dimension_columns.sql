ALTER TABLE lead_designs
ADD COLUMN IF NOT EXISTS desk_mat_length VARCHAR(50),
ADD COLUMN IF NOT EXISTS desk_mat_height VARCHAR(50);

COMMENT ON COLUMN lead_designs.desk_mat_length IS 'Desk mat length/dimension text';
COMMENT ON COLUMN lead_designs.desk_mat_height IS 'Desk mat height/dimension text';

-- Made with Bob
