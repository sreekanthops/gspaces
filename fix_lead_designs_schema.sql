-- Add all missing columns to lead_designs table
DO $$ 
BEGIN
    -- Add has_table column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_table'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_table BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_table column';
    END IF;

    -- Add has_chair column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_chair'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_chair BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_chair column';
    END IF;

    -- Add has_plants column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_plants'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_plants BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_plants column';
    END IF;

    -- Add has_lighting column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_lighting'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_lighting BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_lighting column';
    END IF;

    -- Add has_storage column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_storage'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_storage BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_storage column';
    END IF;

    -- Add has_accessories column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_accessories'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_accessories BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added has_accessories column';
    END IF;

    -- Add table_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'table_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN table_details TEXT;
        RAISE NOTICE 'Added table_details column';
    END IF;

    -- Add chair_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'chair_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN chair_details TEXT;
        RAISE NOTICE 'Added chair_details column';
    END IF;

    -- Add plants_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'plants_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN plants_details TEXT;
        RAISE NOTICE 'Added plants_details column';
    END IF;

    -- Add lighting_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'lighting_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN lighting_details TEXT;
        RAISE NOTICE 'Added lighting_details column';
    END IF;

    -- Add storage_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'storage_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN storage_details TEXT;
        RAISE NOTICE 'Added storage_details column';
    END IF;

    -- Add accessories_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'accessories_details'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN accessories_details TEXT;
        RAISE NOTICE 'Added accessories_details column';
    END IF;

    -- Add notes column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'notes'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN notes TEXT;
        RAISE NOTICE 'Added notes column';
    END IF;

    RAISE NOTICE 'Schema migration completed successfully!';
END $$;

-- Made with Bob
