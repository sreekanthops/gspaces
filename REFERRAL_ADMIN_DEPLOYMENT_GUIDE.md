# Complete Referral Coupon Admin System - Deployment Guide

## Overview
This system gives you **FULL CONTROL** over referral coupons with:
- ✅ Fixed amount discounts (e.g., ₹1000 off)
- ✅ Percentage discounts (e.g., 5% off)
- ✅ Fixed bonuses for referrers (e.g., ₹1000 bonus)
- ✅ Percentage bonuses for referrers (e.g., 5% bonus)
- ✅ Admin UI to manage all referral coupons
- ✅ Individual control per coupon
- ✅ Bulk update options

## What's New

### 1. Enhanced Database Schema
Added columns to `referral_coupons` table for flexible control:
- `discount_type`: 'fixed' or 'percentage'
- `discount_amount`: Fixed discount amount (₹)
- `referrer_bonus_type`: 'fixed' or 'percentage'
- `referrer_bonus_amount`: Fixed bonus amount (₹)
- `min_order_amount`: Minimum order requirement
- `max_discount_amount`: Maximum discount cap
- `first_order_only`: Restrict to first-time users
- `usage_limit`: Total usage limit
- `per_user_limit`: Per-user usage limit
- `description`: Admin notes

### 2. Admin Interface
New admin page at `/admin/referral-coupons` with:
- View all referral coupons
- Edit individual coupon settings
- Toggle active/inactive status
- See usage statistics
- Full control over discounts and bonuses

### 3. Smart Validation
System now supports:
- Both fixed and percentage discounts
- Minimum order requirements
- Usage limits
- First-order restrictions
- Per-user limits

## Deployment Steps

### Step 1: Upgrade Database Schema

```bash
# SSH to your EC2 server
ssh ec2-user@your-server

# Navigate to project directory
cd /home/ec2-user/gspaces

# Pull latest code
git pull origin wallet

# Run database upgrade
psql -U sri -d gspaces -f upgrade_referral_coupons_table.sql
```

This will:
- Add new columns to referral_coupons table
- Set all existing coupons to ₹1000 fixed discount
- Set all existing bonuses to ₹1000 fixed amount

### Step 2: Deploy Updated Code

```bash
# Already pulled in Step 1
# Restart the application
sudo systemctl restart gspaces

# Check logs
sudo journalctl -u gspaces -f
```

### Step 3: Access Admin Interface

1. Login as admin
2. Go to: `https://your-domain.com/admin/referral-coupons`
3. You'll see all referral coupons with full control

## How to Use Admin Interface

### View All Coupons
- See all users' referral coupons
- View usage statistics
- Check active/inactive status

### Edit a Coupon
1. Click "Edit" button on any coupon
2. Configure settings:

**Friend's Discount:**
- Type: Fixed Amount or Percentage
- Amount: e.g., ₹1000 or 10%

**Owner's Bonus:**
- Type: Fixed Amount or Percentage  
- Amount: e.g., ₹1000 or 5%

**Restrictions:**
- Minimum Order: e.g., ₹5000
- Max Discount Cap: e.g., ₹2000
- Usage Limit: Total times code can be used
- Per User Limit: Times each user can use it
- First Order Only: Check to restrict to new customers

3. Click "Save Changes"

### Toggle Active/Inactive
- Click "Activate" or "Deactivate" button
- Inactive coupons cannot be used

## Example Configurations

### Configuration 1: Your Current Request
**Friend Gets:** ₹1000 OFF (fixed)
**Owner Gets:** ₹1000 Bonus (fixed)

```
Discount Type: Fixed Amount
Discount Amount: 1000
Referrer Bonus Type: Fixed Amount
Referrer Bonus Amount: 1000
```

### Configuration 2: Percentage Based
**Friend Gets:** 10% OFF
**Owner Gets:** 10% Bonus

```
Discount Type: Percentage
Discount Percentage: 10
Referrer Bonus Type: Percentage
Referrer Bonus Percentage: 10
```

### Configuration 3: Mixed
**Friend Gets:** ₹500 OFF (fixed)
**Owner Gets:** 5% Bonus (percentage)

```
Discount Type: Fixed Amount
Discount Amount: 500
Referrer Bonus Type: Percentage
Referrer Bonus Percentage: 5
```

### Configuration 4: High-Value Orders
**Friend Gets:** 15% OFF (max ₹3000)
**Owner Gets:** ₹2000 Bonus (fixed)
**Minimum Order:** ₹10,000

```
Discount Type: Percentage
Discount Percentage: 15
Max Discount Amount: 3000
Referrer Bonus Type: Fixed Amount
Referrer Bonus Amount: 2000
Min Order Amount: 10000
```

## How It Works

### When Friend Uses Referral Code

1. **Friend enters code** (e.g., CHITYA14)
2. **System validates:**
   - Code exists and is active
   - Not expired
   - Not self-use
   - Meets minimum order
   - Within usage limits
3. **Calculates discount:**
   - If fixed: Apply exact amount
   - If percentage: Calculate from cart total
   - Apply max cap if set
4. **Shows discount** in cart

### After Payment

1. **Friend gets discount** applied to order
2. **Owner gets bonus** credited to wallet:
   - If fixed: Exact amount
   - If percentage: Calculated from order total
3. **Usage recorded** in database
4. **Statistics updated** for admin view

## Admin Features

### Statistics Dashboard
- Total Coupons
- Active Coupons
- Total Uses
- Total Discounts Given
- Total Bonuses Paid

### Individual Coupon Management
- Edit any coupon's settings
- Change discount amounts
- Change bonus amounts
- Set restrictions
- Toggle active status

### Bulk Operations
Future feature: Update all coupons at once

## Testing

### Test Fixed Amount
1. Set coupon to ₹1000 fixed discount
2. Add ₹5000 worth of items to cart
3. Apply referral code
4. Should see: "₹1000 OFF"

### Test Percentage
1. Set coupon to 10% discount
2. Add ₹5000 worth of items to cart
3. Apply referral code
4. Should see: "₹500 OFF" (10% of ₹5000)

### Test Minimum Order
1. Set minimum order to ₹10,000
2. Add ₹5000 worth of items
3. Apply referral code
4. Should see: "Minimum order amount of ₹10,000 required"

### Test Bonus
1. Friend completes order with referral code
2. Check owner's wallet
3. Should see bonus credited

## Troubleshooting

### Coupon shows "Invalid"
- Check if coupon is active in admin panel
- Verify expiry date
- Check usage limits

### Discount not applying
- Verify minimum order amount is met
- Check if user already used the code
- Ensure code is active

### Bonus not credited
- Check server logs: `sudo journalctl -u gspaces -f`
- Verify referral_coupons table has correct bonus settings
- Check wallet_transactions table for the transaction

## Database Queries

### Check coupon settings:
```sql
SELECT * FROM referral_coupons WHERE coupon_code = 'CHITYA14';
```

### Check usage:
```sql
SELECT * FROM coupon_usage WHERE coupon_code = 'CHITYA14';
```

### Check wallet bonus:
```sql
SELECT * FROM wallet_transactions 
WHERE transaction_type = 'referral_bonus' 
ORDER BY created_at DESC LIMIT 10;
```

### Update all coupons to ₹1000 fixed:
```sql
UPDATE referral_coupons
SET 
    discount_type = 'fixed',
    discount_amount = 1000.00,
    referrer_bonus_type = 'fixed',
    referrer_bonus_amount = 1000.00
WHERE is_active = true;
```

## Files Changed

1. `upgrade_referral_coupons_table.sql` - Database schema upgrade
2. `templates/admin_referral_coupons.html` - Admin UI
3. `admin_referral_routes.py` - Admin routes
4. `wallet_system.py` - Enhanced validation
5. `wallet_routes.py` - Auto-create coupons on signup
6. `main.py` - Updated validation and payment processing

## Summary

You now have **COMPLETE CONTROL** over:
- ✅ How much discount friends get (fixed or %)
- ✅ How much bonus owners get (fixed or %)
- ✅ Minimum order requirements
- ✅ Usage limits
- ✅ Per-user restrictions
- ✅ First-order only options
- ✅ Individual coupon management
- ✅ Real-time statistics

**No more asking for changes - you control everything from the admin panel!** 🎉