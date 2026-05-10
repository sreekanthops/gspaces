# Admin Permission System - Deployment Guide

## Overview
This guide covers the deployment of the granular admin permission system with three permission levels:
- **Read Only**: Can view admin panel only
- **Write Access**: Can view and edit, but not delete
- **Full Admin**: Complete access including delete operations

## Files Modified/Created

### 1. Database Schema
- **File**: `update_admin_permissions_granular.sql`
- **Changes**: 
  - Drops old `admin_level` column
  - Adds three boolean columns: `can_read`, `can_write`, `can_delete`
  - Updates existing admins to have full permissions
  - Adds indexes for performance

### 2. Backend Routes
- **File**: `admin_users_routes.py`
- **Changes**:
  - Replaced `super_admin_required` decorator with `delete_permission_required`
  - Added `write_permission_required` decorator
  - Updated `promote_user()` to accept permission level parameter
  - Updated `revoke_admin()` to clear all permissions
  - Modified queries to use new permission columns

### 3. Frontend Template
- **File**: `templates/admin_users.html`
- **Changes**:
  - Added permission level dropdown (Read, Write, Full)
  - Updated permission badges with color coding
  - Removed toggle buttons from user list
  - Updated form title and descriptions

## Deployment Steps

### Step 1: Backup Database
```bash
pg_dump -U postgres gspaces > gspaces_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Step 2: Apply Database Schema
```bash
psql -U postgres -d gspaces -f update_admin_permissions_granular.sql
```

### Step 3: Verify Schema Changes
```sql
-- Check that columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('can_read', 'can_write', 'can_delete');

-- Check existing admin permissions
SELECT id, name, email, is_admin, can_read, can_write, can_delete
FROM users 
WHERE is_admin = true;
```

### Step 4: Update Application Files
Copy the modified files to your server:
- `admin_users_routes.py`
- `templates/admin_users.html`

### Step 5: Restart Application
```bash
# If using systemd
sudo systemctl restart gspaces

# Or if running manually
pkill -f "python.*main.py"
python main.py
```

## Permission Levels Explained

### Read Only (View)
- Can access admin panel
- Can view all admin sections
- **Cannot** edit or delete anything
- Useful for: Analysts, viewers, auditors

### Write Access (View + Edit)
- Can access admin panel
- Can view all admin sections
- Can edit existing records
- **Cannot** delete records or revoke admin access
- Useful for: Content managers, customer support

### Full Admin (View + Edit + Delete)
- Complete admin access
- Can view, edit, and delete
- Can promote/revoke admin access
- Can perform all administrative actions
- Useful for: System administrators, owners

## How to Grant Admin Access

### Via Admin Panel
1. Go to Admin Panel → Users Management
2. Enter user's email address
3. Select permission level from dropdown:
   - Read Only (View)
   - Write Access (View + Edit)
   - Full Admin (View + Edit + Delete)
4. Click "Grant Admin Access"

### Via Database (Emergency)
```sql
-- Grant Full Admin access
UPDATE users 
SET is_admin = true, 
    can_read = true, 
    can_write = true, 
    can_delete = true 
WHERE email = 'admin@example.com';

-- Grant Write Access
UPDATE users 
SET is_admin = true, 
    can_read = true, 
    can_write = true, 
    can_delete = false 
WHERE email = 'editor@example.com';

-- Grant Read Only access
UPDATE users 
SET is_admin = true, 
    can_read = true, 
    can_write = false, 
    can_delete = false 
WHERE email = 'viewer@example.com';
```

## How to Revoke Admin Access

### Via Admin Panel
1. Go to Admin Panel → Users Management
2. Find the user in the list
3. Click the "Revoke" button (only visible to Full Admins)

### Via Database
```sql
UPDATE users 
SET is_admin = false, 
    can_read = false, 
    can_write = false, 
    can_delete = false 
WHERE email = 'user@example.com';
```

## Testing the Permission System

### Test Read Only Access
1. Create a test user and promote with "Read Only" permission
2. Login as that user
3. Verify:
   - Can access admin panel ✓
   - Can view all sections ✓
   - Cannot see edit buttons ✗
   - Cannot see delete buttons ✗

### Test Write Access
1. Create a test user and promote with "Write Access" permission
2. Login as that user
3. Verify:
   - Can access admin panel ✓
   - Can view all sections ✓
   - Can edit records ✓
   - Cannot delete records ✗
   - Cannot revoke admin access ✗

### Test Full Admin Access
1. Create a test user and promote with "Full Admin" permission
2. Login as that user
3. Verify:
   - Can access admin panel ✓
   - Can view all sections ✓
   - Can edit records ✓
   - Can delete records ✓
   - Can revoke admin access ✓

## Troubleshooting

### Issue: Existing admins can't access admin panel
**Solution**: Run the migration script again to ensure all existing admins have permissions:
```sql
UPDATE users 
SET can_read = true, 
    can_write = true, 
    can_delete = true 
WHERE is_admin = true;
```

### Issue: Permission checks not working
**Solution**: Verify the decorators are applied to routes:
- Delete operations should use `@delete_permission_required`
- Edit operations should use `@write_permission_required`
- View operations should use `@admin_required`

### Issue: Can't promote users
**Solution**: Ensure you have Full Admin permissions:
```sql
SELECT can_delete FROM users WHERE id = YOUR_USER_ID;
```

## Security Considerations

1. **Principle of Least Privilege**: Grant users only the permissions they need
2. **Regular Audits**: Periodically review admin users and their permissions
3. **Revoke Unused Access**: Remove admin access from inactive users
4. **Monitor Actions**: Consider adding audit logging for admin actions
5. **Protect Full Admin**: Limit Full Admin access to trusted personnel only

## Rollback Procedure

If you need to rollback to the old system:

```sql
-- Restore from backup
psql -U postgres -d gspaces < gspaces_backup_YYYYMMDD_HHMMSS.sql

-- Or manually revert
ALTER TABLE users ADD COLUMN admin_level INTEGER DEFAULT 2;
UPDATE users SET admin_level = 1 WHERE is_admin = true;
ALTER TABLE users DROP COLUMN can_read;
ALTER TABLE users DROP COLUMN can_write;
ALTER TABLE users DROP COLUMN can_delete;
```

## Future Enhancements

Consider implementing:
1. **Audit Logging**: Track who made what changes and when
2. **Permission Templates**: Pre-defined permission sets for common roles
3. **Time-Limited Access**: Temporary admin access that expires
4. **IP Restrictions**: Limit admin access to specific IP addresses
5. **Two-Factor Authentication**: Additional security for admin accounts

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the database schema and permissions
3. Check application logs for errors
4. Verify all files were updated correctly

---

**Deployment Date**: 2026-05-10
**Version**: 1.0
**Status**: Ready for Production