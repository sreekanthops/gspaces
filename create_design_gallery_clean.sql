-- Design Gallery Table (Clean - No Sample Data)
-- This creates an empty gallery for you to populate via admin panel

CREATE TABLE IF NOT EXISTS design_gallery (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    image_url VARCHAR(500) NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    category VARCHAR(50) DEFAULT 'Office',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_design_gallery_active ON design_gallery(is_active);
CREATE INDEX IF NOT EXISTS idx_design_gallery_order ON design_gallery(display_order);
CREATE INDEX IF NOT EXISTS idx_design_gallery_category ON design_gallery(category);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_design_gallery_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_design_gallery_timestamp ON design_gallery;
CREATE TRIGGER trigger_update_design_gallery_timestamp
    BEFORE UPDATE ON design_gallery
    FOR EACH ROW
    EXECUTE FUNCTION update_design_gallery_timestamp();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Design Gallery table created successfully! Ready for your uploads.';
END $$;

-- Made with Bob
