# Admin User Management System - Deployment Guide

## Overview
This feature allows existing admins to promote other users to admin status via email address.

## Files Created/Modified

### New Files:
1. **admin_users_routes.py** - Blueprint with admin user management routes
2. **templates/admin_users.html** - Admin user management interface
3. **add_is_admin_column.sql** - Database migration to add is_admin column

### Modified Files:
1. **main.py** - Added blueprint registration and updated load_user function
2. **templates/admin_nav.html** - Added "Manage Users" link

## Deployment Steps

### 1. Database Migration
Run the SQL migration to add the `is_admin` column:
```bash
PGPASSWORD='gspaces2025' psql -h localhost -U gspaces_user -d gspaces_db -f add_is_admin_column.sql
```

### 2. Set Initial Admin
Manually set your first admin user:
```bash
PGPASSWORD='gspaces2025' psql -h localhost -U gspaces_user -d gspaces_db
```
Then run:
```sql
UPDATE users SET is_admin = true WHERE email = 'your@email.com';
```

### 3. Restart Application
```bash
sudo systemctl restart gspaces
sudo systemctl status gspaces
```

### 4. Verify Deployment
- Visit: https://gspaces.in/admin/users
- You should see the admin user management interface
- Test promoting a user by email

## Features

### 1. Promote User by Email
- Enter user's email address in the form
- Click "Promote to Admin"
- User immediately gets admin access

### 2. Toggle Admin Status
- View all users in a table
- Click toggle button to promote/demote users
- Cannot remove your own admin access (safety feature)

### 3. User Statistics
- Total users count
- Total admins count
- Order count per user
- Wallet balance display

## Routes

- `GET /admin/users` - View all users and manage admin status
- `POST /admin/users/promote` - Promote user to admin by email
- `POST /admin/users/<id>/toggle-admin` - Toggle admin status
- `GET /admin/users/search` - AJAX search endpoint (future use)

## Security Features

1. **@admin_required decorator** - Only admins can access these routes
2. **Self-protection** - Users cannot remove their own admin access
3. **Database-driven** - Admin status stored in database, not hardcoded
4. **Fallback support** - Still checks ADMIN_EMAILS list if is_admin column missing

## Troubleshooting

### Issue: "Admin access required" error
**Solution**: Make sure your user has is_admin = true in database

### Issue: "Manage Users" link not showing
**Solution**: Clear browser cache and restart application

### Issue: Cannot promote users
**Solution**: Verify you have admin access and database migration ran successfully

## Testing Checklist

- [ ] Database migration successful
- [ ] Initial admin user set
- [ ] Can access /admin/users page
- [ ] Can promote user by email
- [ ] Can toggle admin status from list
- [ ] Cannot remove own admin access
- [ ] Admin navigation shows "Manage Users" link
- [ ] Non-admin users cannot access the page

## Notes

- The system uses the existing `connect_to_db()` function from main.py
- Admin status is checked on every page load via `load_user()`
- The feature integrates seamlessly with existing admin routes
- Beautiful gradient UI with Bootstrap 5