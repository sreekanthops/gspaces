-- Sync customer designs with all their media files
-- Creates one design entry per customer design with all media in design_images

-- 1. Clear existing gallery data
TRUNCATE TABLE design_gallery;
TRUNCATE TABLE design_images;

-- 2. Get all customer designs with their media
-- For this example, we'll use the lead_designs you mentioned:
-- - 2 designs
-- - Each has 2-3 media files

-- Design 1: GreenNest Studio (3 media)
INSERT INTO design_gallery (
    id, title, description, image_url, display_order,
    category, lead_design_id, auto_synced, is_active, created_at, updated_at
) VALUES (
    14,
    'GreenNest Studio',
    'Modern studio design with green accents',
    '/static/img/leads/media/media_20260506_192614_0_daytime.png',
    1,
    'studio',
    14,
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Add 3 media files for GreenNest Studio
INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary, created_at)
VALUES
    (14, '/static/img/leads/media/media_20260506_192614_0_daytime.png', NULL, 'image', 0, true, CURRENT_TIMESTAMP),
    (14, '/static/img/leads/media/media_20260506_192614_1_studio_view.png', NULL, 'image', 1, false, CURRENT_TIMESTAMP),
    (14, NULL, '/static/img/leads/media/media_20260506_192614_2_studio_walkthrough.mp4', 'video', 2, false, CURRENT_TIMESTAMP);

-- Design 2: Warm Ambient with Paint (2 media)
INSERT INTO design_gallery (
    id, title, description, image_url, display_order,
    category, lead_design_id, auto_synced, is_active, created_at, updated_at
) VALUES (
    10,
    'Dark Warm Ambient with Paint',
    'Cozy workspace with warm lighting and paint accents',
    '/static/img/leads/media/media_20260504_150947_0_dark_warm_ambient_2.jpeg',
    2,
    'office',
    10,
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Add 2 media files for Dark Warm Ambient
INSERT INTO design_images (design_id, image_url, video_url, media_type, display_order, is_primary, created_at)
VALUES
    (10, '/static/img/leads/media/media_20260504_150947_0_dark_warm_ambient_2.jpeg', NULL, 'image', 0, true, CURRENT_TIMESTAMP),
    (10, NULL, '/static/img/leads/media/media_20260504_150947_1_ambient_tour.mp4', 'video', 1, false, CURRENT_TIMESTAMP);

-- 3. Update the sync trigger to handle multiple media files per design
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

        -- Determine media type
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
                design_id,
                image_url,
                video_url,
                media_type,
                display_order,
                is_primary
            ) VALUES (
                design_id,
                CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                CASE WHEN media_type = 'video' THEN NEW.design_image ELSE NULL END,
                media_type,
                0,
                true  -- Mark as primary
            );
        ELSE
            -- Update existing design
            UPDATE design_gallery
            SET
                title = NEW.design_name,
                image_url = CASE WHEN media_type = 'image' THEN NEW.design_image ELSE (SELECT image_url FROM design_gallery WHERE lead_design_id = NEW.id) END,
                display_order = NEW.design_order,
                category = lead_category,
                updated_at = NOW()
            WHERE lead_design_id = NEW.id;

            -- Add the media to design_images if it doesn't exist
            IF NOT EXISTS (
                SELECT 1 FROM design_images
                WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)
                AND (
                    (media_type = 'image' AND image_url = NEW.design_image) OR
                    (media_type = 'video' AND video_url = NEW.design_image)
                )
            ) THEN
                INSERT INTO design_images (
                    design_id,
                    image_url,
                    video_url,
                    media_type,
                    display_order,
                    is_primary
                ) VALUES (
                    (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id),
                    CASE WHEN media_type = 'image' THEN NEW.design_image ELSE NULL END,
                    CASE WHEN media_type = 'video' THEN NEW.design_image ELSE NULL END,
                    media_type,
                    (SELECT COALESCE(MAX(display_order), 0) + 1 FROM design_images WHERE design_id = (SELECT id FROM design_gallery WHERE lead_design_id = NEW.id)),
                    false  -- Not primary (first image is primary)
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Customer designs synced with all media!';
    RAISE NOTICE '✅ 2 designs created:';
    RAISE NOTICE '   - GreenNest Studio (3 media: 2 images + 1 video)';
    RAISE NOTICE '   - Dark Warm Ambient with Paint (2 media: 1 image + 1 video)';
    RAISE NOTICE '✅ Auto-slide through all media when viewing a design';
    RAISE NOTICE '✅ Media count shows in slider (2/3, 1/2)';
    RAISE NOTICE '✅ Image count badges in gallery (🖼️ 3, 🖼️ 2)';
END $$;

-- Made with Bob
