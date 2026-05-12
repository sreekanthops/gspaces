-- Comprehensive Design Gallery Enhancements
-- 1. Add support for multiple media per design with primary image selection
-- 2. Add type field to lead_designs
-- 3. Update category handling

-- Step 1: Add type field to lead_designs
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS type VARCHAR(100);

-- Set default values for existing records
UPDATE lead_designs 
SET type = 'Office Setup' 
WHERE type IS NULL;

-- Step 2: Ensure design_images table exists with proper structure
CREATE TABLE IF NOT EXISTS design_images (
    id SERIAL PRIMARY KEY,
    design_id INTEGER NOT NULL REFERENCES design_gallery(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    video_url TEXT,
    thumbnail_url TEXT,
    media_type VARCHAR(20) DEFAULT 'image',
    display_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_design_images_design_id ON design_images(design_id);
CREATE INDEX IF NOT EXISTS idx_design_images_primary ON design_images(design_id, is_primary);
CREATE INDEX IF NOT EXISTS idx_lead_designs_type ON lead_designs(type);
CREATE INDEX IF NOT EXISTS idx_design_gallery_category ON design_gallery(category);

-- Step 4: Create function to get distinct categories from lead_designs
CREATE OR REPLACE FUNCTION get_active_design_categories()
RETURNS TABLE(category VARCHAR, design_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(dg.category, 'office') as category,
        COUNT(DISTINCT dg.id) as design_count
    FROM design_gallery dg
    WHERE dg.is_active = TRUE
    GROUP BY dg.category
    HAVING COUNT(DISTINCT dg.id) > 0
    ORDER BY design_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create function to get distinct types from lead_designs
CREATE OR REPLACE FUNCTION get_active_design_types()
RETURNS TABLE(type VARCHAR, design_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ld.type, 'Office Setup') as type,
        COUNT(DISTINCT dg.id) as design_count
    FROM design_gallery dg
    INNER JOIN lead_designs ld ON dg.lead_design_id = ld.id
    WHERE dg.is_active = TRUE AND ld.type IS NOT NULL
    GROUP BY ld.type
    HAVING COUNT(DISTINCT dg.id) > 0
    ORDER BY design_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Update trigger to sync primary image from design_images to design_gallery
CREATE OR REPLACE FUNCTION sync_primary_image_to_gallery()
RETURNS TRIGGER AS $$
BEGIN
    -- When a design_image is set as primary, update the design_gallery main image
    IF NEW.is_primary = TRUE THEN
        -- Unset other primary images for this design
        UPDATE design_images 
        SET is_primary = FALSE 
        WHERE design_id = NEW.design_id AND id != NEW.id;
        
        -- Update the main image in design_gallery
        UPDATE design_gallery 
        SET image_url = NEW.image_url,
            updated_at = NOW()
        WHERE id = NEW.design_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_primary_image ON design_images;
CREATE TRIGGER trigger_sync_primary_image
    AFTER INSERT OR UPDATE OF is_primary ON design_images
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION sync_primary_image_to_gallery();

-- Step 7: Verify the setup
SELECT 'Design Gallery Tables Setup Complete' as status;

-- Show current categories
SELECT * FROM get_active_design_categories();

-- Show current types
SELECT * FROM get_active_design_types();

-- Show sample design with media count
SELECT 
    dg.id,
    dg.title,
    dg.category,
    ld.type,
    COUNT(di.id) as media_count,
    dg.image_url as primary_image
FROM design_gallery dg
LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id
LEFT JOIN design_images di ON dg.id = di.design_id
WHERE dg.is_active = TRUE
GROUP BY dg.id, dg.title, dg.category, ld.type, dg.image_url
ORDER BY dg.created_at DESC
LIMIT 5;

-- Made with Bob
