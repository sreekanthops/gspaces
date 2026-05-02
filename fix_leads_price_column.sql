-- Add missing price column to lead_designs table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'price'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN price DECIMAL(10,2) DEFAULT 0;
        RAISE NOTICE 'Added price column to lead_designs table';
    ELSE
        RAISE NOTICE 'Price column already exists in lead_designs table';
    END IF;
END $$;

-- Made with Bob
