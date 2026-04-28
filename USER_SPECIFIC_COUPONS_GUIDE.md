# User-Specific Coupons Feature Guide

## Overview
This feature allows administrators to create coupons that are exclusive to specific users. Only the assigned user can see and redeem these coupons in their wallet.

## Features Implemented

### 1. Admin Panel Enhancements
- **Coupon Scope Selector**: Choose between "Public" (all users) or "User-Specific" (single user)
- **Customer Dropdown**: When "User-Specific" is selected, a dropdown appears with all registered customers
- **Visual Indicators**: Admin coupon table shows 👤 User-Specific or 🌐 Public badges
- **Add/Edit Support**: Both creating new coupons and editing existing ones support user assignment

### 2. User Wallet Display
- User-specific coupons automatically appear in the user's wallet "Available Coupons" section
- Only the assigned user can see their exclusive coupons
- Other users cannot see or use these coupons

### 3. Backend Validation
- Coupon redemption validates that `coupon.user_id` matches `current_user.id`
- Public coupons (user_id = NULL) are available to all users
- User-specific coupons are only redeemable by the assigned user

## How to Use

### Creating a User-Specific Coupon

1. **Navigate to Admin Panel**
   - Go to `/admin/coupons`
   - Click "Add New Coupon"

2. **Fill in Coupon Details**
   - **Coupon Code**: e.g., `SPECIAL100`
   - **Coupon Type**: Order/Wallet/Both
   - **Discount Type**: Percentage or Fixed
   - **Discount Value**: e.g., 100 for ₹100 off
   - **Coupon Scope**: Select "User-Specific"
   - **Select Customer**: Choose the customer from dropdown
   - Fill in other fields (expiry, min order, etc.)

3. **Save**
   - Click "Create Coupon"
   - Success message will show "(User-Specific)" indicator

### Editing User Assignment

1. **Click Edit** on any coupon in the admin table
2. **Change Scope**:
   - To make public: Select "Public (All Users)"
   - To assign to user: Select "User-Specific" and choose customer
3. **Save Changes**

### User Experience

**For the Assigned User:**
- Logs into their account
- Goes to Profile → Wallet tab
- Sees their exclusive coupon in "Available Coupons" section
- Can redeem it like any other coupon

**For Other Users:**
- Cannot see the user-specific coupon
- Cannot use the coupon code even if they know it
- Backend validation prevents unauthorized redemption

## Technical Details

### Database Schema
The `coupons` table uses the `user_id` column:
- `user_id = NULL`: Public coupon (all users)
- `user_id = <user_id>`: User-specific coupon (only that user)

### API Endpoints

**Get Customers List** (for dropdown):
```
GET /admin/customers/list
Response: { "status": "success", "customers": [...] }
```

**Add Coupon** (with user_id):
```
POST /admin/coupons/add
Form Data:
  - coupon_scope: "public" | "user_specific"
  - user_id: <user_id> (if user_specific)
  - ... other coupon fields
```

**Edit Coupon** (update user_id):
```
POST /admin/coupons/edit/<coupon_id>
Form Data:
  - coupon_scope: "public" | "user_specific"
  - user_id: <user_id> (if user_specific)
  - ... other coupon fields
```

**Get Coupon** (includes user_id):
```
GET /admin/coupons/get/<coupon_id>
Response: { "status": "success", "coupon": { ..., "user_id": <id> } }
```

### Files Modified

1. **templates/admin_coupons.html**
   - Added coupon scope selector
   - Added customer dropdown with dynamic loading
   - Added scope column in table
   - JavaScript for handling scope changes

2. **main.py**
   - `add_coupon()`: Handles user_id assignment
   - `edit_coupon()`: Updates user_id
   - `get_coupon()`: Returns user_id
   - `get_customers_list()`: New API endpoint
   - `admin_coupons()`: Fetches user_id in query
   - `profile()`: Updated bonus coupons query

## Deployment Steps

1. **Backup Database**
   ```bash
   pg_dump gspaces > backup_before_user_coupons.sql
   ```

2. **Verify Schema**
   - Ensure `coupons` table has `user_id` column
   - If not, run: `ALTER TABLE coupons ADD COLUMN user_id INTEGER REFERENCES users(id);`

3. **Deploy Code**
   ```bash
   git pull origin <branch-name>
   sudo systemctl restart gspaces
   ```

4. **Test**
   - Create a test user-specific coupon
   - Log in as that user and verify it appears
   - Log in as different user and verify it doesn't appear
   - Try redeeming as assigned user (should work)
   - Try redeeming as different user (should fail)

## Use Cases

### 1. VIP Customer Rewards
Create exclusive high-value coupons for top customers

### 2. Customer Service Recovery
Provide compensation coupons to specific customers who had issues

### 3. Personalized Promotions
Send targeted offers to specific customer segments

### 4. Influencer/Partner Deals
Create special coupons for business partners or influencers

### 5. Birthday/Anniversary Gifts
Automatically assign special coupons on customer milestones

## Security Considerations

- ✅ Backend validation prevents unauthorized redemption
- ✅ User-specific coupons hidden from other users
- ✅ Admin-only access to coupon management
- ✅ Database foreign key ensures user exists
- ✅ Coupon code uniqueness maintained

## Future Enhancements (Optional)

1. **Bulk Assignment**: Assign same coupon to multiple users
2. **User Groups**: Create coupons for user segments (e.g., "Premium Members")
3. **Auto-Assignment Rules**: Automatically assign coupons based on criteria
4. **Expiry Notifications**: Email users before their exclusive coupons expire
5. **Usage Analytics**: Track redemption rates for user-specific vs public coupons

## Support

For issues or questions:
- Check server logs: `sudo journalctl -u gspaces -f`
- Verify database: `SELECT * FROM coupons WHERE user_id IS NOT NULL;`
- Test API: `curl http://localhost:5000/admin/customers/list`

---

**Feature Status**: ✅ Complete and Ready for Deployment
**Last Updated**: 2026-04-28