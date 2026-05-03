-- Add Profile Lighting columns to lead_designs table
-- This adds a new item type while keeping the existing lighting (which will be renamed to Rope Lighting in the UI)

ALTER TABLE lead_designs
ADD COLUMN IF NOT EXISTS has_profile_lighting BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_lighting_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS profile_lighting_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS profile_lighting_details TEXT DEFAULT '';

-- Note: The existing 'lighting' columns will be renamed to 'Rope Lighting' in the UI only
-- Database columns remain as 'lighting' for backward compatibility

-- Made with Bob
