-- Fix Admin Access for Setups/Leads Page
-- This sets the is_admin flag for your admin user

-- First, let's see all users and their admin status
SELECT 'Current users and admin status:' as info;
SELECT id, username, email, is_admin FROM users ORDER BY id;

-- Update your admin user to have admin access
-- Replace 'your_admin_email@example.com' with your actual admin email
-- Or use username if you know it

-- Option 1: Set admin by email
-- UPDATE users SET is_admin = true WHERE email = 'your_admin_email@example.com';

-- Option 2: Set admin by username  
-- UPDATE users SET is_admin = true WHERE username = 'admin';

-- Option 3: Set admin by user ID (if you know it)
-- UPDATE users SET is_admin = true WHERE id = 1;

-- Option 4: Set ALL users as admin (use carefully!)
-- UPDATE users SET is_admin = true;

-- After running the UPDATE, verify:
SELECT 'Updated admin status:' as info;
SELECT id, username, email, is_admin FROM users WHERE is_admin = true;

-- Instructions:
-- 1. Uncomment ONE of the UPDATE statements above
-- 2. Replace the email/username/id with your actual admin credentials
-- 3. Run this script: psql -U sri -d gspaces -f fix_admin_access.sql
-- 4. Log out and log back in to the admin panel

-- Made with Bob
