-- Add wardrobe dimension columns to lead_designs table
-- This enables area-based pricing for wardrobes (length × width × price_per_sqft)

DO $$
BEGIN
    -- Add wardrobes_length_ft column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'wardrobes_length_ft'
    ) THEN
        ALTER TABLE lead_designs 
        ADD COLUMN wardrobes_length_ft NUMERIC(10,2) DEFAULT 6.0;
        RAISE NOTICE 'Added wardrobes_length_ft column';
    ELSE
        RAISE NOTICE 'wardrobes_length_ft column already exists';
    END IF;

    -- Add wardrobes_width_ft column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'wardrobes_width_ft'
    ) THEN
        ALTER TABLE lead_designs 
        ADD COLUMN wardrobes_width_ft NUMERIC(10,2) DEFAULT 2.0;
        RAISE NOTICE 'Added wardrobes_width_ft column';
    ELSE
        RAISE NOTICE 'wardrobes_width_ft column already exists';
    END IF;

    -- Add wardrobes_height_ft column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'wardrobes_height_ft'
    ) THEN
        ALTER TABLE lead_designs 
        ADD COLUMN wardrobes_height_ft NUMERIC(10,2) DEFAULT 7.0;
        RAISE NOTICE 'Added wardrobes_height_ft column';
    ELSE
        RAISE NOTICE 'wardrobes_height_ft column already exists';
    END IF;
END $$;

-- Verify the columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'lead_designs'
AND column_name IN ('wardrobes_length_ft', 'wardrobes_width_ft', 'wardrobes_height_ft')
ORDER BY column_name;
