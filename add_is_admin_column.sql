-- Add is_admin column to users table
-- This is needed for admin access control on leads/setups page

-- Add the is_admin column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Set your admin user (replace with your actual email)
-- Uncomment ONE of these lines:

-- Option 1: Set admin by email (RECOMMENDED)
-- UPDATE users SET is_admin = true WHERE email = 'your_email@example.com';

-- Option 2: Set admin by ID (usually 1 for first user)
-- UPDATE users SET is_admin = true WHERE id = 1;

-- Option 3: Set admin by name
-- UPDATE users SET is_admin = true WHERE name = 'Your Name';

-- Verify the column was added and admin is set
SELECT 'Users table updated!' as status;
SELECT id, name, email, is_admin FROM users ORDER BY id;

-- Instructions:
-- 1. Run this script AS-IS first: psql -U sri -d gspaces -f add_is_admin_column.sql
-- 2. Note your user's email, name, or ID from the output
-- 3. Edit this file and uncomment ONE UPDATE statement
-- 4. Replace with your actual email/name/id
-- 5. Run the script again
-- 6. Log out and log back in to admin panel

-- Made with Bob
