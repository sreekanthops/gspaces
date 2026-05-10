-- Sync all quotation media_files into design_gallery/design_images
-- So gallery cards get correct image counts and detail pages show all media
-- Also backfills already-synced rows

CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
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

        SELECT COALESCE(design_category, 'office') INTO lead_category
        FROM leads
        WHERE id = NEW.lead_id;

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

        -- Find first image from media_files, fallback to design_image
        first_image_url := NULL;

        FOR media_item IN
            SELECT value
            FROM jsonb_array_elements(COALESCE(NEW.media_files, '[]'::jsonb))
        LOOP
            IF COALESCE(media_item ->> 'type', 'image') = 'image' THEN
                first_image_url := media_item ->> 'url';
                EXIT;
            END IF;
        END LOOP;

        first_image_url := COALESCE(first_image_url, NULLIF(NEW.design_image, ''));

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

        -- Rebuild gallery media from quotation media_files
        DELETE FROM design_images
        WHERE design_id = gallery_id;

        IF jsonb_array_length(COALESCE(NEW.media_files, '[]'::jsonb)) > 0 THEN
            FOR media_item IN
                SELECT value
                FROM jsonb_array_elements(COALESCE(NEW.media_files, '[]'::jsonb))
            LOOP
                media_type := COALESCE(media_item ->> 'type', 'image');
                media_url := media_item ->> 'url';
                media_order_num := COALESCE(NULLIF(media_item ->> 'order', '')::INTEGER, 0);

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
            INSERT INTO design_images (
                design_id, image_url, display_order, is_primary
            ) VALUES (
                gallery_id,
                NEW.design_image,
                0,
                true
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger explicitly
DROP TRIGGER IF EXISTS trigger_sync_lead_design ON lead_designs;
CREATE TRIGGER trigger_sync_lead_design
    AFTER INSERT OR UPDATE ON lead_designs
    FOR EACH ROW
    EXECUTE FUNCTION sync_lead_design_to_gallery();

-- Backfill all already-synced gallery media from quotation media_files
DO $$
DECLARE
    ld_record RECORD;
BEGIN
    FOR ld_record IN
        SELECT ld.*
        FROM lead_designs ld
        JOIN design_gallery dg ON dg.lead_design_id = ld.id
        WHERE dg.auto_synced = true
    LOOP
        PERFORM sync_lead_design_to_gallery_trigger_wrapper(ld_record.id);
    END LOOP;
EXCEPTION
    WHEN undefined_function THEN
        RAISE NOTICE 'Wrapper function not found; run manual backfill query below if needed.';
END $$;

-- Manual backfill for environments without wrapper helper:
-- Run this after the function is updated to touch synced lead designs and re-trigger sync.
UPDATE lead_designs
SET updated_at = CURRENT_TIMESTAMP
WHERE id IN (
    SELECT lead_design_id
    FROM design_gallery
    WHERE auto_synced = true
      AND lead_design_id IS NOT NULL
);

-- Verification: show gallery designs with media counts
SELECT
    dg.id,
    dg.title,
    dg.lead_design_id,
    dg.image_url,
    COUNT(di.id) AS media_count
FROM design_gallery dg
LEFT JOIN design_images di ON di.design_id = dg.id
WHERE dg.auto_synced = true
GROUP BY dg.id, dg.title, dg.lead_design_id, dg.image_url
ORDER BY dg.updated_at DESC, dg.id DESC
LIMIT 25;

-- Made with Bob
