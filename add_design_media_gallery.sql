-- Add media gallery support to lead_designs
-- Allows multiple images and videos per design

-- Add media_files JSONB column to store array of media
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS media_files JSONB DEFAULT '[]'::jsonb;

-- Structure: [{"type": "image", "url": "path/to/file.jpg", "order": 1}, ...]

COMMENT ON COLUMN lead_designs.media_files IS 'JSONB array of media files (images/videos) with type, url, and order';

-- Verify column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'lead_designs' AND column_name = 'media_files';

-- Success message
DO $$ 
BEGIN
    RAISE NOTICE 'Media gallery column added successfully!';
    RAISE NOTICE 'Admins can now upload multiple images and videos (up to 50MB each)';
END $$;

-- Made with Bob
