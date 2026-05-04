-- Ensure lighting_length_ft and profile_lighting_length_ft columns exist
-- These columns store the length in feet for rope lighting and profile lighting

DO $$
BEGIN
    -- Add lighting_length_ft if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'lighting_length_ft'
    ) THEN
        ALTER TABLE lead_designs 
        ADD COLUMN lighting_length_ft DECIMAL(10,2) DEFAULT 10;
        RAISE NOTICE 'Added lighting_length_ft column';
    ELSE
        RAISE NOTICE 'lighting_length_ft column already exists';
    END IF;

    -- Add profile_lighting_length_ft if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'profile_lighting_length_ft'
    ) THEN
        ALTER TABLE lead_designs 
        ADD COLUMN profile_lighting_length_ft DECIMAL(10,2) DEFAULT 10;
        RAISE NOTICE 'Added profile_lighting_length_ft column';
    ELSE
        RAISE NOTICE 'profile_lighting_length_ft column already exists';
    END IF;
END $$;

-- Verify the columns
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'lead_designs'
AND column_name IN ('lighting_length_ft', 'profile_lighting_length_ft')
ORDER BY column_name;

-- Made with Bob
