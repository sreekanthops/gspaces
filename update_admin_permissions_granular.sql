-- Update admin permissions to support granular access control
-- Permission levels: read, write, full

-- Drop the old admin_level column if it exists
ALTER TABLE users DROP COLUMN IF EXISTS admin_level;

-- Add new permission columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS can_read BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS can_write BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS can_delete BOOLEAN DEFAULT FALSE;

-- Update existing admins to have full permissions
UPDATE users 
SET can_read = TRUE, can_write = TRUE, can_delete = TRUE 
WHERE is_admin = TRUE;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_can_read ON users(can_read);
CREATE INDEX IF NOT EXISTS idx_users_can_write ON users(can_write);
CREATE INDEX IF NOT EXISTS idx_users_can_delete ON users(can_delete);

-- Add comments
COMMENT ON COLUMN users.can_read IS 'Permission to view admin panel (Read access)';
COMMENT ON COLUMN users.can_write IS 'Permission to edit/update data (Write access)';
COMMENT ON COLUMN users.can_delete IS 'Permission to delete data (Full admin access)';

-- Display current admin users with their permissions
SELECT id, name, email, is_admin,
       can_read as "Read",
       can_write as "Write", 
       can_delete as "Delete",
       CASE 
           WHEN can_delete THEN 'Full Admin'
           WHEN can_write THEN 'Write Access'
           WHEN can_read THEN 'Read Only'
           ELSE 'No Access'
       END as permission_level
FROM users 
WHERE is_admin = TRUE
ORDER BY can_delete DESC, can_write DESC, can_read DESC, id ASC;

-- Made with Bob
