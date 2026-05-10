-- Add support for multiple images per design
-- Creates a separate table for design images (one-to-many relationship)

-- Create design_images table
CREATE TABLE IF NOT EXISTS design_images (
    id SERIAL PRIMARY KEY,
    design_id INTEGER NOT NULL REFERENCES design_gallery(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_design FOREIGN KEY (design_id) REFERENCES design_gallery(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_design_images_design_id ON design_images(design_id);
CREATE INDEX IF NOT EXISTS idx_design_images_order ON design_images(display_order);
CREATE INDEX IF NOT EXISTS idx_design_images_primary ON design_images(is_primary);

-- Migrate existing single images to design_images table
-- Set them as primary images
INSERT INTO design_images (design_id, image_url, display_order, is_primary)
SELECT id, image_url, 0, true
FROM design_gallery
WHERE image_url IS NOT NULL AND image_url != ''
ON CONFLICT DO NOTHING;

-- Add lead_design_id column to track which lead_design it came from
ALTER TABLE design_gallery ADD COLUMN IF NOT EXISTS lead_design_id INTEGER REFERENCES lead_designs(id) ON DELETE SET NULL;
ALTER TABLE design_gallery ADD COLUMN IF NOT EXISTS auto_synced BOOLEAN DEFAULT false;

-- Create index on lead_design_id
CREATE INDEX IF NOT EXISTS idx_design_gallery_lead_design_id ON design_gallery(lead_design_id);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Design gallery images table created successfully!';
    RAISE NOTICE 'Existing images migrated as primary images.';
    RAISE NOTICE 'Lead sync columns added.';
END $$;

-- Made with Bob
