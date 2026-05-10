-- Quick fix to ensure the user who was promoted has is_admin set to true
-- Run this to verify and fix any admin access issues

-- Check current admin status
SELECT id, name, email, is_admin, 
       COALESCE(can_read, FALSE) as can_read,
       COALESCE(can_write, FALSE) as can_write,
       COALESCE(can_delete, FALSE) as can_delete
FROM users 
WHERE email = 'YOUR_USER_EMAIL_HERE';  -- Replace with the actual email

-- If is_admin is false, update it:
-- UPDATE users 
-- SET is_admin = true,
--     can_read = true,
--     can_write = true,  -- or false for read-only
--     can_delete = true  -- or false for write access
-- WHERE email = 'YOUR_USER_EMAIL_HERE';

-- Verify all admins have proper flags
SELECT id, name, email, is_admin,
       COALESCE(can_read, FALSE) as can_read,
       COALESCE(can_write, FALSE) as can_write,
       COALESCE(can_delete, FALSE) as can_delete
FROM users 
WHERE is_admin = true
ORDER BY id;

-- Made with Bob
