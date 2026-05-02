-- Set admin status for your user account
-- Run this on the server to grant yourself admin access

-- Option 1: Set admin by email (RECOMMENDED)
UPDATE users SET is_admin = true WHERE email = 'sri.chityala501@gmail.com';

-- Verify it worked
SELECT id, name, email, is_admin FROM users WHERE email = 'sri.chityala501@gmail.com';

-- Option 2: If you need to set admin for multiple users
-- UPDATE users SET is_admin = true WHERE email IN ('email1@example.com', 'email2@example.com');

-- Option 3: View all users and their admin status
-- SELECT id, name, email, is_admin FROM users ORDER BY is_admin DESC, id ASC;

-- Made with Bob
