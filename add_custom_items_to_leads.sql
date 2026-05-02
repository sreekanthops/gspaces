-- Add custom_items column to lead_designs table for flexible item additions
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'custom_items'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN custom_items JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added custom_items column to lead_designs table';
    ELSE
        RAISE NOTICE 'custom_items column already exists in lead_designs table';
    END IF;
END $$;

-- Example of custom_items structure:
-- [
--   {"name": "Monitor Stand", "details": "Adjustable height monitor stand", "icon": "🖥️"},
--   {"name": "Cable Management", "details": "Under-desk cable tray", "icon": "🔌"}
-- ]

-- Made with Bob
