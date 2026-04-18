# Personal Coupon Feature - Deployment Guide

## 🎯 Overview

This feature allows admins to create personal coupons for individual users directly from the admin referral coupons page. Personal coupons are user-specific, auto-expire in 3 months, and users receive email notifications.

## ✨ Features Implemented

### 1. **Admin Interface**
- ✅ "Create Personal Coupon" section in Edit modal
- ✅ Auto-generated coupon codes: `PERSONAL_USERNAME_RANDOM`
- ✅ Discount type: Fixed amount (₹) or Percentage (%)
- ✅ Reason/description field
- ✅ 3-month auto-expiry
- ✅ Removed old "Adjust Wallet" button (now integrated in Edit form)

### 2. **Database Schema**
- ✅ Added `user_id` column to `coupons` table (nullable, references users)
- ✅ Added `is_personal` column (boolean, default FALSE)
- ✅ Indexes for performance

### 3. **Backend Logic**
- ✅ Personal coupon creation in `/admin/referral-coupons/update` route
- ✅ Updated `/api/coupons/available` to show personal + public coupons
- ✅ Personal coupons sorted first in the list

### 4. **Email Notifications**
- ✅ Beautiful HTML email template
- ✅ Shows coupon code, discount, expiry date, and reason
- ✅ Direct link to shop

### 5. **Cart Display**
- ✅ Personal coupons shown with special "🎁 PERSONAL" badge
- ✅ Purple gradient background for personal coupons
- ✅ Personal coupons appear first in the list

## 📦 Files Changed

```
add_personal_coupons.sql          - Database schema
admin_referral_routes.py          - Backend logic
email_helper.py                   - Email function
templates/admin_referral_coupons.html - Admin UI
templates/cart.html               - Cart display
main.py                           - API endpoint
```

## 🚀 Deployment Steps

### Step 1: Update Database Schema

SSH to server and run:

```bash
cd /home/ec2-user/gspaces

# Apply database changes
psql -U sri -d gspaces -f add_personal_coupons.sql
```

Expected output:
```
ALTER TABLE
CREATE INDEX
ALTER TABLE
COMMENT
COMMENT
```

### Step 2: Deploy Code

```bash
# Pull latest changes
git fetch origin
git checkout wallet
git pull origin wallet

# Restart application
sudo systemctl restart gspaces

# Check status
sudo systemctl status gspaces
```

### Step 3: Verify Deployment

1. **Check Database**
   ```bash
   psql -U sri -d gspaces -c "\d coupons"
   ```
   Should show `user_id` and `is_personal` columns

2. **Test Admin Interface**
   - Go to: https://gspaces.in/admin/referral-coupons
   - Click "Edit" on any user
   - Scroll to "🎁 Create Personal Coupon" section
   - Should see discount type dropdown and fields

3. **Create Test Personal Coupon**
   - Select discount type: "Fixed Amount (₹)"
   - Enter amount: 100
   - Enter reason: "Test personal coupon"
   - Click "Save Changes"
   - Should see success message with coupon code

4. **Verify Email Sent**
   - Check user's email inbox
   - Should receive email with coupon code and details

5. **Test in Cart**
   - Login as the user who received the coupon
   - Go to cart page
   - Click "🎁 View Available Coupons"
   - Personal coupon should appear first with purple badge

## 🧪 Testing Checklist

- [ ] Database schema updated successfully
- [ ] Admin can create personal coupons
- [ ] Coupon codes are auto-generated correctly
- [ ] Email notifications are sent
- [ ] Personal coupons appear in cart with badge
- [ ] Personal coupons can be applied at checkout
- [ ] Coupons expire after 3 months
- [ ] Only the specific user can see their personal coupons
- [ ] Public coupons still work for everyone

## 📊 Database Queries for Verification

### Check personal coupons
```sql
SELECT code, user_id, is_personal, discount_type, discount_value, 
       valid_until, created_at
FROM coupons 
WHERE is_personal = TRUE
ORDER BY created_at DESC;
```

### Check user's personal coupons
```sql
SELECT c.code, c.discount_type, c.discount_value, c.description,
       u.name, u.email, c.valid_until
FROM coupons c
JOIN users u ON c.user_id = u.id
WHERE c.is_personal = TRUE AND u.email = 'user@example.com';
```

### Check coupon usage
```sql
SELECT c.code, c.is_personal, COUNT(cu.id) as times_used
FROM coupons c
LEFT JOIN coupon_usage cu ON c.id = cu.coupon_id
WHERE c.is_personal = TRUE
GROUP BY c.id, c.code, c.is_personal;
```

## 🎨 UI Features

### Admin Interface
- **Location**: Edit modal in admin referral coupons page
- **Section**: "🎁 Create Personal Coupon"
- **Fields**:
  - Discount Type dropdown (Fixed/Percentage/Don't Create)
  - Discount Amount/Percentage input
  - Reason/Description input
- **Note**: "Coupon will auto-expire in 3 months. User will receive email notification."

### Cart Display
- **Personal Badge**: Purple gradient "🎁 PERSONAL" badge
- **Background**: Light purple gradient
- **Border**: Purple color (#8b5cf6)
- **Position**: Personal coupons appear first

## 📧 Email Template

Subject: `🎁 Special Coupon Just for You, {user_name}!`

Content includes:
- Personalized greeting
- Discount amount prominently displayed
- Coupon code in large monospace font
- Expiry date
- Reason (if provided)
- "Shop Now" button
- Usage instructions

## 🔒 Security Features

- ✅ Only admins can create personal coupons
- ✅ Personal coupons are user-specific (user_id check)
- ✅ User ID not exposed in API responses
- ✅ Coupons auto-expire after 3 months
- ✅ All actions logged with admin email

## 🐛 Troubleshooting

### Issue: Personal coupon not showing in cart
**Solution**: 
1. Check if user is logged in
2. Verify coupon is active: `SELECT * FROM coupons WHERE code = 'COUPON_CODE';`
3. Check expiry date
4. Clear browser cache

### Issue: Email not sent
**Solution**:
1. Check SMTP configuration in environment variables
2. Check server logs: `sudo journalctl -u gspaces -f`
3. Verify email address is valid

### Issue: Coupon code already exists
**Solution**: The system generates random codes, but if collision occurs:
1. Try creating again (new random code will be generated)
2. Check existing codes: `SELECT code FROM coupons WHERE code LIKE 'PERSONAL_%';`

## 📈 Monitoring

### Track personal coupon usage
```sql
SELECT 
    DATE(cu.used_at) as date,
    COUNT(*) as personal_coupons_used,
    SUM(cu.discount_applied) as total_discount
FROM coupon_usage cu
JOIN coupons c ON cu.coupon_id = c.id
WHERE c.is_personal = TRUE
GROUP BY DATE(cu.used_at)
ORDER BY date DESC;
```

### Most active personal coupon users
```sql
SELECT 
    u.name,
    u.email,
    COUNT(DISTINCT c.id) as coupons_received,
    COUNT(cu.id) as coupons_used
FROM users u
LEFT JOIN coupons c ON u.id = c.user_id AND c.is_personal = TRUE
LEFT JOIN coupon_usage cu ON c.id = cu.coupon_id
GROUP BY u.id, u.name, u.email
HAVING COUNT(DISTINCT c.id) > 0
ORDER BY coupons_used DESC;
```

## 🎯 Use Cases

1. **Loyalty Rewards**: Give special discounts to loyal customers
2. **Apology Coupons**: Compensate for service issues
3. **Birthday Offers**: Create personal birthday coupons
4. **VIP Treatment**: Exclusive discounts for VIP customers
5. **Referral Bonuses**: Additional rewards for top referrers

## 📝 Notes

- Personal coupons can coexist with referral coupons
- Users can have multiple personal coupons
- Personal coupons are prioritized in the cart display
- Expiry is automatically set to 3 months from creation
- Coupon codes are unique and auto-generated

---

**Deployment Date**: April 18, 2026  
**Branch**: wallet  
**Status**: ✅ Ready for Production