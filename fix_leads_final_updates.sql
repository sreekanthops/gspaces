-- Final updates for leads system
-- Add multi_socket, fix custom_items, add plant height fields

DO $$ 
BEGIN
    -- Add multi_socket fields
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'has_multi_socket'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN has_multi_socket BOOLEAN DEFAULT FALSE;
        ALTER TABLE lead_designs ADD COLUMN multi_socket_quantity INTEGER DEFAULT 1;
        ALTER TABLE lead_designs ADD COLUMN multi_socket_price DECIMAL(10,2) DEFAULT 0;
        ALTER TABLE lead_designs ADD COLUMN multi_socket_details TEXT;
        RAISE NOTICE 'Added multi_socket columns';
    END IF;
    
    -- Add plant height fields
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'big_plants_height_ft'
    ) THEN
        ALTER TABLE lead_designs ADD COLUMN big_plants_height_ft DECIMAL(5,1) DEFAULT 3.0;
        ALTER TABLE lead_designs ADD COLUMN mini_plants_height_ft DECIMAL(5,1) DEFAULT 1.0;
        RAISE NOTICE 'Added plant height columns';
    END IF;
    
    -- Ensure custom_items is JSONB type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_designs' AND column_name = 'custom_items' AND data_type = 'text'
    ) THEN
        -- Convert TEXT to JSONB
        ALTER TABLE lead_designs ALTER COLUMN custom_items TYPE JSONB USING custom_items::jsonb;
        RAISE NOTICE 'Converted custom_items to JSONB';
    END IF;
    
    -- Set default for custom_items if NULL
    UPDATE lead_designs SET custom_items = '[]'::jsonb WHERE custom_items IS NULL;
    
END $$;

-- Made with Bob