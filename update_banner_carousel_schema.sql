-- Update homepage_banner table to support multiple carousel images
-- Add carousel support and image management

-- First, let's modify the existing table to support carousel
ALTER TABLE homepage_banner ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE homepage_banner ADD COLUMN IF NOT EXISTS slide_duration INTEGER DEFAULT 5000; -- milliseconds
ALTER TABLE homepage_banner ADD COLUMN IF NOT EXISTS enable_carousel BOOLEAN DEFAULT FALSE;

-- Create a new table for carousel images
CREATE TABLE IF NOT EXISTS homepage_carousel_images (
    id SERIAL PRIMARY KEY,
    image_url VARCHAR(500) NOT NULL,
    title VARCHAR(200),
    subtitle TEXT,
    button_text VARCHAR(100),
    button_link VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_carousel_images_active ON homepage_carousel_images(is_active, display_order);

-- Insert default carousel image from existing banner
INSERT INTO homepage_carousel_images (image_url, title, subtitle, button_text, button_link, display_order, is_active)
SELECT banner_image, title, subtitle, button_text, button_link, 0, TRUE
FROM homepage_banner 
WHERE is_active = TRUE
LIMIT 1
ON CONFLICT DO NOTHING;

-- Update homepage_banner to enable carousel by default
UPDATE homepage_banner SET enable_carousel = TRUE WHERE is_active = TRUE;

COMMENT ON TABLE homepage_carousel_images IS 'Stores multiple banner images for homepage carousel';
COMMENT ON COLUMN homepage_carousel_images.display_order IS 'Order in which images appear in carousel (0 = first)';
COMMENT ON COLUMN homepage_carousel_images.slide_duration IS 'Not used here, controlled by homepage_banner.slide_duration';

-- Made with Bob
