-- Add category field to leads table for design gallery sync
-- This allows customers to select category when creating leads

-- Add category column to leads table
ALTER TABLE leads ADD COLUMN IF NOT EXISTS design_category VARCHAR(50) DEFAULT 'office';

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_leads_design_category ON leads(design_category);

-- Update the sync trigger to use lead's category instead of hardcoded 'office'
CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
BEGIN
    -- Only sync if design_image is not null
    IF NEW.design_image IS NOT NULL AND NEW.design_image != '' THEN
        -- Get the category from the parent lead
        SELECT COALESCE(design_category, 'office') INTO lead_category
        FROM leads
        WHERE id = NEW.lead_id;
        
        -- Check if this lead_design is already synced
        IF NOT EXISTS (
            SELECT 1 FROM design_gallery 
            WHERE lead_design_id = NEW.id
        ) THEN
            -- Insert into design_gallery
            INSERT INTO design_gallery (
                title,
                description,
                image_url,
                display_order,
                category,
                lead_design_id,
                auto_synced,
                is_active
            ) VALUES (
                NEW.design_name,
                'Auto-synced from customer lead',
                NEW.design_image,
                NEW.design_order,
                lead_category,  -- Use lead's category
                NEW.id,
                true,
                false -- Start as inactive, admin can review and activate
            );
        ELSE
            -- Update existing entry if image or name changed
            UPDATE design_gallery
            SET 
                title = NEW.design_name,
                image_url = NEW.design_image,
                display_order = NEW.design_order,
                category = lead_category,  -- Update category too
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Category field added to leads table!';
    RAISE NOTICE '✅ Sync trigger updated to use lead category!';
    RAISE NOTICE 'Customers can now select: Office, Home, Commercial, or Studio';
END $$;

-- Made with Bob
