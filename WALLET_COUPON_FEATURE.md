# Wallet Coupon Feature Implementation Guide

## Overview
This feature allows users to redeem coupons to add money directly to their wallet balance. Admin can create wallet-specific coupons with expiry dates, and each coupon can only be used once per user.

## Key Features
1. **Coupon Types**: Order, Wallet, or Both
2. **Expiry Control**: Expiry or Non-Expiry coupons
3. **One-Time Usage**: Each coupon can only be used once per user
4. **Admin Control**: Full control over coupon creation and management
5. **Wallet Integration**: Direct wallet balance addition

## Database Changes

### New Fields in `coupons` table:
- `coupon_type` VARCHAR(20): 'order', 'wallet', or 'both'
- `expiry_type` VARCHAR(20): 'expiry' or 'non_expiry'
- `user_id` INTEGER: For personal coupons (NULL for public)

### Updated `coupon_usage` table:
- `usage_type` VARCHAR(20): 'order' or 'wallet'
- `order_id` now nullable (wallet coupons don't have orders)
- New constraint: `unique_coupon_user_usage` (coupon_id, user_id, usage_type)

## Implementation Steps

### 1. Database Migration
Run: `add_wallet_coupon_support.sql`

### 2. Admin Interface Updates
**File**: `templates/admin_coupons.html`
- Add "Coupon Type" dropdown (Order/Wallet/Both)
- Add "Expiry Type" dropdown (Expiry/Non-Expiry)
- Update table to show coupon type
- Update edit form with new fields

### 3. Backend Routes
**File**: `main.py` or create `wallet_coupon_routes.py`

#### New Route: `/wallet/redeem_coupon` (POST)
- Validates coupon code
- Checks if coupon is wallet-type or both
- Verifies expiry date
- Checks one-time usage per user
- Adds amount to wallet
- Records usage in coupon_usage table

#### Update Route: `/admin/add_coupon` (POST)
- Accept new fields: coupon_type, expiry_type
- Save to database

#### Update Route: `/admin/edit_coupon` (POST)
- Accept and update new fields

### 4. Wallet Page UI
**File**: `templates/wallet.html`
- Add "Redeem Coupon" section
- Input field for coupon code
- Submit button
- Success/error messages
- Show redeemed coupons history

### 5. Validation Logic
- Coupon must be active
- Coupon must not be expired (if expiry_type = 'expiry')
- Coupon must be wallet-type or both
- User must not have used this coupon before
- Coupon usage limit not exceeded (if set)

## Example Coupon: GSPACES_DESKS_FOLLOW
- Code: GSPACES_DESKS_FOLLOW
- Type: Wallet
- Value: ₹1000
- Expiry: 30 days from creation
- Usage: One-time per user

## API Endpoints

### POST /wallet/redeem_coupon
**Request:**
```json
{
  "coupon_code": "GSPACES_DESKS_FOLLOW"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "₹1000 added to your wallet!",
  "new_balance": 1500.00,
  "amount_added": 1000.00
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Coupon already used"
}
```

## Security Considerations
1. One coupon per user enforcement
2. Expiry date validation
3. Coupon type validation
4. Transaction logging
5. Wallet balance integrity

## Testing Checklist
- [ ] Create wallet coupon from admin
- [ ] Redeem coupon successfully
- [ ] Try to redeem same coupon twice (should fail)
- [ ] Try expired coupon (should fail)
- [ ] Try order-only coupon in wallet (should fail)
- [ ] Verify wallet balance updated
- [ ] Check coupon usage tracking
- [ ] Test non-expiry coupons

## Made with Bob