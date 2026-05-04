-- Add dimension fields for table, storage, and measurements for wood/lighting items
-- This will help display proper dimensions on quotation page

DO $$ 
BEGIN
    -- Table dimensions
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'table_length_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN table_length_ft DECIMAL(5,1) DEFAULT 4.0;
        ALTER TABLE lead_designs ADD COLUMN table_width_ft DECIMAL(5,1) DEFAULT 2.0;
        ALTER TABLE lead_designs ADD COLUMN table_height_inch DECIMAL(5,1) DEFAULT 29.0;
        RAISE NOTICE 'Added table dimension columns';
    END IF;
    
    -- Storage dimensions
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'storage_length_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN storage_length_ft DECIMAL(5,1) DEFAULT 3.0;
        ALTER TABLE lead_designs ADD COLUMN storage_width_ft DECIMAL(5,1) DEFAULT 1.5;
        ALTER TABLE lead_designs ADD COLUMN storage_height_ft DECIMAL(5,1) DEFAULT 6.0;
        RAISE NOTICE 'Added storage dimension columns';
    END IF;
    
    -- Lighting measurements (in feet)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'lighting_length_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN lighting_length_ft DECIMAL(5,1) DEFAULT 10.0;
        RAISE NOTICE 'Added lighting length column';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'profile_lighting_length_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN profile_lighting_length_ft DECIMAL(5,1) DEFAULT 10.0;
        RAISE NOTICE 'Added profile lighting length column';
    END IF;
    
    -- Wood items measurements (for frames, wall racks, etc.)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'frames_size_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN frames_size_ft VARCHAR(50) DEFAULT '2x3';
        RAISE NOTICE 'Added frames size column';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'wall_racks_length_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN wall_racks_length_ft DECIMAL(5,1) DEFAULT 4.0;
        RAISE NOTICE 'Added wall racks length column';
    END IF;
    
END $$;

-- Made with Bob