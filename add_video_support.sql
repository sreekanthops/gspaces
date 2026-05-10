-- Add video support to design images
-- Add media_type column to distinguish between images and videos

-- 1. Add media_type column to design_images
ALTER TABLE design_images ADD COLUMN IF NOT EXISTS media_type VARCHAR(10) DEFAULT 'image';

-- 2. Add video_url column for video files
ALTER TABLE design_images ADD COLUMN IF NOT EXISTS video_url VARCHAR(500);

-- 3. Add thumbnail_url column for video thumbnails
ALTER TABLE design_images ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500);

-- 4. Update the sync trigger to handle videos
CREATE OR REPLACE FUNCTION sync_lead_design_to_gallery()
RETURNS TRIGGER AS $$
DECLARE
    lead_category VARCHAR(50);
    design_id INTEGER;
    media_type VARCHAR(10);
BEGIN
    -- Only sync if design_image is not null
    IF NEW.design_image IS NOT NULL AND NEW.design_image != '' THEN
        -- Get the category from the parent lead
        SELECT COALESCE(design_category, 'office') INTO lead_category
        FROM leads
        WHERE id = NEW.lead_id;

        -- Determine media type (simple check for video extensions)
        IF NEW.design_image LIKE '%.mp4' OR NEW.design_image LIKE '%.mov' OR NEW.design_image LIKE '%.webm' THEN
            media_type := 'video';
        ELSE
            media_type := 'image';
        END IF;

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
                CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                NEW.design_order,
                lead_category,
                NEW.id,
                true,
                false -- Start as inactive for admin review
            ) RETURNING id INTO design_id;

            -- Add the media to design_images table
            INSERT INTO design_images (
                design_id, image_url, video_url, thumbnail_url,
                display_order, is_primary, media_type
            ) VALUES (
                design_id,
                CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                CASE WHEN media_type = 'video' THEN NEW.design_image ELSE NULL END,
                NULL,  -- thumbnail_url (can be added later)
                0,
                true,  -- Mark as primary
                media_type
            );
        ELSE
            -- Update existing entry if design name or image changed
            UPDATE design_gallery
            SET
                title = NEW.design_name,
                image_url = CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                display_order = NEW.design_order,
                category = lead_category,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;

            -- Update or add the media in design_images
            IF EXISTS (
                SELECT 1 FROM design_images
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)
                AND (
                    (media_type = 'image' AND image_url = NEW.design_image) OR
                    (media_type = 'video' AND video_url = NEW.design_image)
                )
            ) THEN
                -- Update existing media
                UPDATE design_images
                SET
                    display_order = 0,
                    is_primary = true,
                    media_type = media_type,
                    updated_at = NOW()
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)
                AND (
                    (media_type = 'image' AND image_url = NEW.design_image) OR
                    (media_type = 'video' AND video_url = NEW.design_image)
                );
            ELSE
                -- Add new media
                INSERT INTO design_images (
                    design_id, image_url, video_url, thumbnail_url,
                    display_order, is_primary, media_type
                ) VALUES (
                    (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id),
                    CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                    CASE WHEN media_type = 'video' THEN NEW.design_image ELSE NULL END,
                    NULL,  -- thumbnail_url
                    0,
                    true,
                    media_type
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
    RAISE NOTICE '✅ Video support added to design images!';
    RAISE NOTICE '✅ Media type column added (image/video)';
    RAISE NOTICE '✅ Video URL and thumbnail support added';
    RAISE NOTICE '✅ Sync trigger updated for videos';
END $$;

-- Made with Bob
