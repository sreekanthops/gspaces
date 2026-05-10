-- Update sync trigger to handle multiple images per design
-- Creates one design entry with multiple images in design_images table

CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
    design_id INTEGER;
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
            -- Insert into design_gallery (one entry per design)
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
                lead_category,
                NEW.id,
                true,
                false -- Start as inactive for admin review
            ) RETURNING id INTO design_id;

            -- Add the image to design_images table
            INSERT INTO design_images (
                design_id, image_url, display_order, is_primary
            ) VALUES (
                design_id,
                NEW.design_image,
                0,
                true  -- Mark as primary
            );
        ELSE
            -- Update existing entry if design name or image changed
            UPDATE design_gallery
            SET
                title = NEW.design_name,
                image_url = NEW.design_image,
                display_order = NEW.design_order,
                category = lead_category,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;

            -- Update or add the image in design_images
            IF EXISTS (
                SELECT 1 FROM design_images
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)
                AND image_url = NEW.design_image
            ) THEN
                -- Update existing image
                UPDATE design_images
                SET
                    display_order = 0,
                    is_primary = true,
                    updated_at = NOW()
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)
                AND image_url = NEW.design_image;
            ELSE
                -- Add new image
                INSERT INTO design_images (
                    design_id, image_url, display_order, is_primary
                ) VALUES (
                    (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id),
                    NEW.design_image,
                    0,
                    true
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Sync trigger updated for multiple images!';
    RAISE NOTICE '✅ One design entry per lead design';
    RAISE NOTICE '✅ All images stored in design_images table';
    RAISE NOTICE '✅ Primary images marked';
END $$;

-- Made with Bob
