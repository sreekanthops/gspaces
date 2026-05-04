-- Fix custom_items column to be JSONB for proper parsing
-- This will ensure custom items display correctly on quotation page

DO $$
BEGIN
    -- Check if custom_items is TEXT and convert to JSONB
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' 
        AND column_name = 'custom_items' 
        AND data_type = 'text'
    ) THEN
        -- First, clean up any invalid JSON
        UPDATE lead_designs 
        SET custom_items = '[]'::jsonb 
        WHERE custom_items IS NULL OR custom_items = '' OR custom_items = 'null';
        
        -- Convert valid JSON strings to JSONB
        ALTER TABLE lead_designs 
        ALTER COLUMN custom_items TYPE JSONB USING 
            CASE 
                WHEN custom_items IS NULL OR custom_items = '' THEN '[]'::jsonb
                ELSE custom_items::jsonb
            END;
        
        RAISE NOTICE 'Converted custom_items column from TEXT to JSONB';
    ELSE
        RAISE NOTICE 'custom_items column is already JSONB or does not exist';
    END IF;
END $$;

-- Made with Bob
