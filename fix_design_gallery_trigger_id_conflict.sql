-- Fix the sync trigger to avoid ID conflicts in design_gallery table
-- The issue is that the trigger was not properly handling the auto-increment ID

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

        -- Check if gallery entry exists for this lead_design_id
        IF NOT EXISTS (
            SELECT 1 FROM design_gallery WHERE lead_design_id = NEW.id
        ) THEN
            -- Insert new gallery entry (let the sequence generate the ID automatically)
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
            -- Update existing gallery entry
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

        -- Clear existing media for this gallery entry
        DELETE FROM design_images
        WHERE design_id = gallery_id;

        -- Insert media files
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

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_sync_lead_design ON lead_designs;
CREATE TRIGGER trigger_sync_lead_design
    AFTER INSERT OR UPDATE ON lead_designs
    FOR EACH ROW
    EXECUTE FUNCTION sync_lead_design_to_gallery();

-- Check for any orphaned or conflicting entries
SELECT 
    dg.id as gallery_id,
    dg.lead_design_id,
    dg.title,
    ld.id as actual_lead_design_id,
    ld.design_name
FROM design_gallery dg
LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id
WHERE dg.auto_synced = true
ORDER BY dg.id DESC
LIMIT 20;

-- Made with Bob
