-- Use lead-level customer notes (leads.notes) for gallery description text
-- instead of lead_designs.notes, with fallback to design item details.

CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
    lead_notes TEXT;
    gallery_description TEXT;
    gallery_id INTEGER;
    media_item JSONB;
    media_url TEXT;
    media_type TEXT;
    first_image_url TEXT;
    media_order_num INTEGER;
BEGIN
    -- Require either primary design image or media_files
    IF (NEW.design_image IS NOT NULL AND NEW.design_image != '')
       OR jsonb_array_length(COALESCE(NEW.media_files, '[]'::jsonb)) > 0 THEN

        SELECT
            COALESCE(design_category, 'office'),
            NULLIF(BTRIM(notes), '')
        INTO lead_category, lead_notes
        FROM leads
        WHERE id = NEW.lead_id;

        gallery_description := COALESCE(
            lead_notes,
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

        first_image_url := NULL;

        FOR media_item IN
            SELECT value
            FROM jsonb_array_elements(COALESCE(NEW.media_files, '[]'::jsonb))
            ORDER BY COALESCE(NULLIF(value ->> 'order', '')::INTEGER, 0)
        LOOP
            IF COALESCE(media_item ->> 'type', 'image') = 'image' THEN
                first_image_url := media_item ->> 'url';
                EXIT;
            END IF;
        END LOOP;

        first_image_url := COALESCE(first_image_url, NULLIF(NEW.design_image, ''));

        IF first_image_url IS NOT NULL AND first_image_url != '' AND first_image_url NOT LIKE '/static/%' THEN
            first_image_url := '/static/' || first_image_url;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM design_gallery WHERE lead_design_id = NEW.id
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
                first_image_url,
                NEW.design_order,
                lead_category,
                NEW.id,
                true,
                false
            ) RETURNING id INTO gallery_id;
        ELSE
            UPDATE design_gallery
            SET
                title = NEW.design_name,
                description = gallery_description,
                image_url = first_image_url,
                display_order = NEW.design_order,
                category = lead_category,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id
            RETURNING id INTO gallery_id;
        END IF;

        DELETE FROM design_images
        WHERE design_id = gallery_id;

        IF jsonb_array_length(COALESCE(NEW.media_files, '[]'::jsonb)) > 0 THEN
            FOR media_item IN
                SELECT value
                FROM jsonb_array_elements(COALESCE(NEW.media_files, '[]'::jsonb))
                ORDER BY COALESCE(NULLIF(value ->> 'order', '')::INTEGER, 0)
            LOOP
                media_type := COALESCE(media_item ->> 'type', 'image');
                media_url := media_item ->> 'url';
                media_order_num := COALESCE(NULLIF(media_item ->> 'order', '')::INTEGER, 0);

                IF media_url IS NOT NULL AND media_url != '' AND media_url NOT LIKE '/static/%' THEN
                    media_url := '/static/' || media_url;
                END IF;

                IF media_url IS NOT NULL AND media_url != '' THEN
                    INSERT INTO design_images (
                        design_id,
                        image_url,
                        video_url,
                        media_type,
                        display_order,
                        is_primary
                    ) VALUES (
                        gallery_id,
                        CASE
                            WHEN media_type = 'video' THEN first_image_url
                            ELSE media_url
                        END,
                        CASE
                            WHEN media_type = 'video' THEN media_url
                            ELSE NULL
                        END,
                        media_type,
                        media_order_num,
                        (media_type = 'image' AND media_url = first_image_url)
                    );
                END IF;
            END LOOP;
        ELSIF NEW.design_image IS NOT NULL AND NEW.design_image != '' THEN
            media_url := NEW.design_image;
            IF media_url NOT LIKE '/static/%' THEN
                media_url := '/static/' || media_url;
            END IF;

            INSERT INTO design_images (
                design_id, image_url, display_order, is_primary
            ) VALUES (
                gallery_id,
                media_url,
                0,
                true
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_lead_design ON lead_designs;
CREATE TRIGGER trigger_sync_lead_design
    AFTER INSERT OR UPDATE ON lead_designs
    FOR EACH ROW
    EXECUTE FUNCTION sync_lead_design_to_gallery();

-- Backfill existing auto-synced gallery descriptions from leads.notes first
UPDATE design_gallery dg
SET description = COALESCE(
        NULLIF(BTRIM(l.notes), ''),
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
JOIN leads l ON l.id = ld.lead_id
WHERE dg.lead_design_id = ld.id
  AND dg.auto_synced = true;

SELECT dg.id, dg.title, dg.description, dg.lead_design_id
FROM design_gallery dg
WHERE dg.auto_synced = true
ORDER BY dg.updated_at DESC, dg.id DESC
LIMIT 20;

-- Made with Bob
