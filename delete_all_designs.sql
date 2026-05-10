-- Delete all existing designs from gallery
-- Run this to start with a clean slate

DELETE FROM design_gallery;

-- Reset the ID sequence to start from 1
ALTER SEQUENCE design_gallery_id_seq RESTART WITH 1;

-- Confirmation message
DO $$
BEGIN
    RAISE NOTICE 'All designs deleted successfully! Gallery is now empty and ready for your uploads.';
END $$;

-- Made with Bob
