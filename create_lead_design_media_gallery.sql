-- Enhanced Media Gallery for Lead Designs
-- Supports up to 5 media files (max 2 videos, max 3 images)
-- Image size: 5MB, Video size: 50MB

-- Add media_files JSONB column if not exists
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS media_files JSONB DEFAULT '[]'::jsonb;

-- Structure: [
--   {"type": "image", "url": "path/to/file.jpg", "order": 1, "size": 1024000},
--   {"type": "video", "url": "path/to/file.mp4", "order": 2, "size": 5120000}
-- ]

COMMENT ON COLUMN lead_designs.media_files IS 'JSONB array of media files with validation: max 5 files (2 videos, 3 images), 5MB images, 50MB videos';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_lead_designs_media ON lead_designs USING GIN (media_files);

-- Verify column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'lead_designs' AND column_name = 'media_files';

-- Success message
DO $$ 
BEGIN
    RAISE NOTICE '✅ Media gallery column ready!';
    RAISE NOTICE '📸 Max 3 images (5MB each)';
    RAISE NOTICE '🎥 Max 2 videos (50MB each)';
    RAISE NOTICE '🎠 Auto carousel with navigation';
    RAISE NOTICE '🔍 Full-screen lightbox view';
END $$;

-- Made with Bob