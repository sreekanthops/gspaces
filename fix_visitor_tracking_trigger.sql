-- Fix visitor tracking trigger error
-- The table doesn't have updated_at column but trigger is trying to set it

-- Option 1: Drop the trigger (recommended since we don't need it)
DROP TRIGGER IF EXISTS update_visitor_tracking_updated_at ON visitor_tracking;
DROP TRIGGER IF EXISTS update_page_views_updated_at ON page_views;
DROP TRIGGER IF EXISTS update_visitor_events_updated_at ON visitor_events;

-- Option 2: If you want to keep the trigger, add the column
-- ALTER TABLE visitor_tracking ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
-- ALTER TABLE page_views ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
-- ALTER TABLE visitor_events ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Made with Bob
