# Permanent Referral Coupon Fix

## Problem
When users share their referral codes with friends, the codes show as "invalid" because:
1. Referral coupons weren't being created automatically during signup
2. Existing users don't have referral coupon entries in the database

## Solution - Two Parts

### Part 1: Fix Existing Users (One-Time)
Run this SQL script to create referral coupons for ALL existing users who don't have them:

```bash
cd /home/ec2-user/gspaces
psql -U sri -d gspaces -f create_all_missing_referral_coupons.sql
```

Or run directly:
```bash
psql -U sri -d gspaces << 'EOF'
INSERT INTO referral_coupons (
    user_id, coupon_code, discount_percentage, 
    referral_bonus_percentage, times_used, 
    total_referral_earnings, is_active, 
    created_at, expires_at
)
SELECT 
    u.id, u.referral_code, 5.00, 5.00, 0, 0.00, true, 
    NOW(), NOW() + INTERVAL '365 days'
FROM users u
WHERE u.referral_code IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM referral_coupons rc WHERE rc.user_id = u.id
  );

SELECT COUNT(*) as total_created FROM referral_coupons;
EOF
```

### Part 2: Auto-Create for New Users (Permanent)
Updated `wallet_routes.py` to automatically create referral coupons during signup.

**Deploy the updated files:**

```bash
# On your local machine
cd /Users/sreekanthchityala/gspaces
git add wallet_routes.py main.py create_all_missing_referral_coupons.sql
git commit -m "Auto-create referral coupons for all users"
git push

# On EC2 server
cd /home/ec2-user/gspaces
git pull origin wallet

# Run the SQL fix for existing users
psql -U sri -d gspaces -f create_all_missing_referral_coupons.sql

# Restart the application
sudo systemctl restart gspaces
sudo journalctl -u gspaces -f
```

## What Changed

### 1. wallet_routes.py - integrate_wallet_with_signup() function
Now automatically:
- Credits signup bonus (₹500)
- Creates referral coupon entry with:
  - User's referral code
  - 5% discount for referred users
  - 5% bonus for referrer
  - 1 year validity
  - Active status

### 2. main.py - validate_coupon() function
Now checks:
- Regular coupons table first
- Then referral_coupons table if not found
- Validates referral code properly
- Returns discount info for both types

### 3. main.py - payment_success() function
Now processes:
- Referral bonuses after successful payment
- Awards 5% to referrer's wallet
- Records coupon usage
- Updates coupon statistics

## Verification

Check if all users have referral coupons:
```bash
psql -U sri -d gspaces -c "
SELECT 
    COUNT(DISTINCT u.id) as total_users,
    COUNT(DISTINCT rc.user_id) as users_with_coupons
FROM users u
LEFT JOIN referral_coupons rc ON u.id = rc.user_id
WHERE u.referral_code IS NOT NULL;
"