-- Fix media gallery issues
-- 1. The media files are using old format with "media_" prefix
-- 2. Need to update to match the upload route format

-- Check current media files
SELECT id, design_name, media_files FROM lead_designs WHERE media_files IS NOT NULL AND media_files != '[]'::jsonb;

-- The files should be accessible but directory is missing
-- Files are saved as: img/leads/media/media_20260503_141712_0_white_wash.png
-- But directory /var/www/gspaces/static/img/leads/media/ doesn't exist

