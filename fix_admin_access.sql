-- Fix Admin Access for Setups/Leads Page
-- This sets the is_admin flag for your admin user

-- First, let's see what columns exist in the users table
SELECT 'Checking users table structure:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Now let's see all users and their admin status
SELECT 'Current users and admin status:' as info;
SELECT id, email, is_admin FROM users ORDER BY id;

-- Update your admin user to have admin access
-- Uncomment ONE of the options below and replace with your actual email/id

-- Option 1: Set admin by email (RECOMMENDED)
-- UPDATE users SET is_admin = true WHERE email = 'your_admin_email@example.com';

-- Option 2: Set admin by user ID (if you know it, usually 1)
-- UPDATE users SET is_admin = true WHERE id = 1;

-- Option 3: Set ALL users as admin (use carefully!)
-- UPDATE users SET is_admin = true;

-- After running the UPDATE, verify:
SELECT 'Updated admin status:' as info;
SELECT id, email, is_admin FROM users WHERE is_admin = true;

-- Instructions:
-- 1. First run this script AS-IS to see your users table structure
-- 2. Note your admin user's email or ID
-- 3. Edit this file and uncomment ONE UPDATE statement
-- 4. Replace the email/id with your actual admin credentials
-- 5. Run this script again: psql -U sri -d gspaces -f fix_admin_access.sql
-- 6. Log out and log back in to the admin panel

-- Made with Bob
