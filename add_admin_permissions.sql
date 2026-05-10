-- Add admin permission levels to users table
-- This allows differentiation between super admins and regular admins

-- Add admin_level column (1 = super admin with delete, 2 = regular admin without delete)
ALTER TABLE users ADD COLUMN IF NOT EXISTS admin_level INTEGER DEFAULT 2;

-- Update existing admins to super admin level
UPDATE users SET admin_level = 1 WHERE is_admin = true;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_admin_level ON users(admin_level);

-- Comments
COMMENT ON COLUMN users.admin_level IS 'Admin permission level: 1=Super Admin (full access), 2=Regular Admin (no delete)';

-- Display current admin users
SELECT id, name, email, is_admin, admin_level,
       CASE 
           WHEN admin_level = 1 THEN 'Super Admin (Full Access)'
           WHEN admin_level = 2 THEN 'Regular Admin (No Delete)'
           ELSE 'User'
       END as permission_level
FROM users 
WHERE is_admin = true
ORDER BY admin_level ASC, id ASC;

-- Made with Bob
