-- Add quantity fields for all items in lead_designs table
-- Price will be calculated as: unit_price × quantity

-- Add quantity columns for existing items
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS table_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS chair_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS plants_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS lighting_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS storage_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS accessories_quantity INTEGER DEFAULT 1;

-- Add new permanent item fields with quantity and price
ALTER TABLE lead_designs
ADD COLUMN IF NOT EXISTS has_big_plants BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS big_plants_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS big_plants_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS big_plants_details TEXT,

ADD COLUMN IF NOT EXISTS has_mini_plants BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS mini_plants_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS mini_plants_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS mini_plants_details TEXT,

ADD COLUMN IF NOT EXISTS has_frames BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS frames_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS frames_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS frames_details TEXT,

ADD COLUMN IF NOT EXISTS has_wall_racks BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS wall_racks_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS wall_racks_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS wall_racks_details TEXT,

ADD COLUMN IF NOT EXISTS has_deskmat BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deskmat_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS deskmat_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS deskmat_details TEXT,

ADD COLUMN IF NOT EXISTS has_dustbin BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS dustbin_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS dustbin_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS dustbin_details TEXT,

ADD COLUMN IF NOT EXISTS has_floor_mat BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS floor_mat_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS floor_mat_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS floor_mat_details TEXT,

ADD COLUMN IF NOT EXISTS has_keyboard BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS keyboard_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS keyboard_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS keyboard_details TEXT,

ADD COLUMN IF NOT EXISTS has_mouse BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS mouse_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS mouse_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS mouse_details TEXT,

ADD COLUMN IF NOT EXISTS has_paint BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS paint_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS paint_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS paint_details TEXT,

ADD COLUMN IF NOT EXISTS has_wardrobes BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS wardrobes_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS wardrobes_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS wardrobes_details TEXT;

-- Add comments
COMMENT ON COLUMN lead_designs.table_quantity IS 'Number of desks/tables';
COMMENT ON COLUMN lead_designs.chair_quantity IS 'Number of chairs';
COMMENT ON COLUMN lead_designs.big_plants_quantity IS 'Number of big plants';
COMMENT ON COLUMN lead_designs.mini_plants_quantity IS 'Number of mini plants';
COMMENT ON COLUMN lead_designs.frames_quantity IS 'Number of frames';
COMMENT ON COLUMN lead_designs.wall_racks_quantity IS 'Number of wall racks';
COMMENT ON COLUMN lead_designs.deskmat_quantity IS 'Number of desk mats';
COMMENT ON COLUMN lead_designs.dustbin_quantity IS 'Number of dustbins';
COMMENT ON COLUMN lead_designs.floor_mat_quantity IS 'Number of floor mats';
COMMENT ON COLUMN lead_designs.keyboard_quantity IS 'Number of keyboards';
COMMENT ON COLUMN lead_designs.mouse_quantity IS 'Number of mice';
COMMENT ON COLUMN lead_designs.paint_quantity IS 'Paint quantity (liters/cans)';
COMMENT ON COLUMN lead_designs.wardrobes_quantity IS 'Number of wardrobes';

-- Success message
DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Item Quantities Migration Complete!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Added quantity fields for all items';
    RAISE NOTICE 'Added 11 new permanent item types';
    RAISE NOTICE 'Total items now: 17 (6 original + 11 new)';
END $$;

-- Made with Bob
