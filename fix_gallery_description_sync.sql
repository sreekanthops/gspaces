-- Fix gallery sync to use customer design notes/details instead of default auto-sync text
-- Also backfill existing synced gallery rows

CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
    gallery_description TEXT;
    design_id INTEGER;
BEGIN
    -- Only sync if design_image is not null
    IF NEW.design_image IS NOT NULL AND NEW.design_image != '' THEN
        -- Get category from parent lead
        SELECT COALESCE(design_category, 'office') INTO lead_category
        FROM leads
        WHERE id = NEW.lead_id;

        -- Prefer customer-entered notes/details for gallery description
        gallery_description := COALESCE(
            NULLIF(BTRIM(NEW.notes), ''),
            NULLIF(BTRIM(NEW.table_details), ''),
            NULLIF(BTRIM(NEW.chair_details), ''),
            NULLIF(BTRIM(NEW.lighting_details), ''),
            NULLIF(BTRIM(NEW.profile_lighting_details), ''),
            NULLIF(BTRIM(NEW.storage_details), ''),
            NULLIF(BTRIM(NEW.big_plants_details), ''),
            NULLIF(BTRIM(NEW.mini_plants_details), ''),
            NULLIF(BTRIM(NEW.frames_details), ''),
            NULLIF(BTRIM(NEW.wall_racks_details), ''),
            NULLIF(BTRIM(NEW.dustbin_details), ''),
            NULLIF(BTRIM(NEW.paint_details), ''),
            NULLIF(BTRIM(NEW.wardrobes_details), ''),
            NULLIF(BTRIM(NEW.desk_mat_details), ''),
            NULLIF(BTRIM(NEW.multi_socket_details), ''),
            NULLIF(BTRIM(NEW.desk_lamp_details), ''),
            NULLIF(BTRIM(NEW.pen_holder_details), ''),
            NULLIF(BTRIM(NEW.laptop_holder_details), ''),
            'Auto-synced from customer lead'
        );

        IF NOT EXISTS (
            SELECT 1 FROM design_gallery
            WHERE lead_design_id = NEW.id
        ) THEN
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
                gallery_description,
                NEW.design_image,
                NEW.design_order,
                lead_category,
                NEW.id,
                true,
                false
            ) RETURNING id INTO design_id;

            INSERT INTO design_images (
                design_id, image_url, display_order, is_primary
            ) VALUES (
                design_id,
                NEW.design_image,
                0,
                true
            );
        ELSE
            UPDATE design_gallery
            SET
                title = NEW.design_name,
                description = gallery_description,
                image_url = NEW.design_image,
                display_order = NEW.design_order,
                category = lead_category,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;

            IF EXISTS (
                SELECT 1 FROM design_images
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id LIMIT 1)
                  AND image_url = NEW.design_image
            ) THEN
                UPDATE design_images
                SET
                    display_order = 0,
                    is_primary = true,
                    updated_at = NOW()
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id LIMIT 1)
                  AND image_url = NEW.design_image;
            ELSE
                INSERT INTO design_images (
                    design_id, image_url, display_order, is_primary
                ) VALUES (
                    (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id LIMIT 1),
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

-- Backfill existing synced gallery descriptions from current lead_designs data
UPDATE design_gallery dg
SET description = COALESCE(
        NULLIF(BTRIM(ld.notes), ''),
        NULLIF(BTRIM(ld.table_details), ''),
        NULLIF(BTRIM(ld.chair_details), ''),
        NULLIF(BTRIM(ld.lighting_details), ''),
        NULLIF(BTRIM(ld.profile_lighting_details), ''),
        NULLIF(BTRIM(ld.storage_details), ''),
        NULLIF(BTRIM(ld.big_plants_details), ''),
        NULLIF(BTRIM(ld.mini_plants_details), ''),
        NULLIF(BTRIM(ld.frames_details), ''),
        NULLIF(BTRIM(ld.wall_racks_details), ''),
        NULLIF(BTRIM(ld.dustbin_details), ''),
        NULLIF(BTRIM(ld.paint_details), ''),
        NULLIF(BTRIM(ld.wardrobes_details), ''),
        NULLIF(BTRIM(ld.desk_mat_details), ''),
        NULLIF(BTRIM(ld.multi_socket_details), ''),
        NULLIF(BTRIM(ld.desk_lamp_details), ''),
        NULLIF(BTRIM(ld.pen_holder_details), ''),
        NULLIF(BTRIM(ld.laptop_holder_details), ''),
        dg.description,
        'Auto-synced from customer lead'
    ),
    updated_at = CURRENT_TIMESTAMP
FROM lead_designs ld
WHERE dg.lead_design_id = ld.id
  AND dg.auto_synced = true;

-- Optional verification
SELECT dg.id, dg.title, dg.description, dg.lead_design_id
FROM design_gallery dg
WHERE dg.auto_synced = true
ORDER BY dg.updated_at DESC, dg.id DESC
LIMIT 20;

-- Made with Bob
