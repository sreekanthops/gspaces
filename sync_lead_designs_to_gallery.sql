-- Function to sync lead designs to design gallery
-- This will automatically add lead design images to the public gallery

CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
BEGIN
    -- Only sync if design_image is not null
    IF NEW.design_image IS NOT NULL AND NEW.design_image != '' THEN
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
                'office', -- default category
                NEW.id,
                true,
                false -- Start as inactive, admin can review and activate
            );
        ELSE
            -- Update existing entry if image changed
            UPDATE design_gallery
            SET 
                title = NEW.design_name,
                image_url = NEW.design_image,
                display_order = NEW.design_order,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on lead_designs table
DROP TRIGGER IF EXISTS trigger_sync_lead_design ON lead_designs;
CREATE TRIGGER trigger_sync_lead_design
    AFTER INSERT OR UPDATE ON lead_designs
    FOR EACH ROW
    EXECUTE FUNCTION sync_lead_design_to_gallery();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Lead design sync trigger created successfully!';
    RAISE NOTICE 'New lead designs will automatically appear in design gallery (as inactive).';
END $$;

-- Made with Bob
