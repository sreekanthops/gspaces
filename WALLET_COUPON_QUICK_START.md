# Wallet Coupon Feature - Quick Start Guide

## 🚀 Quick Deployment (5 Minutes)

### Step 1: Run Deployment Script
```bash
./deploy_wallet_coupon_feature.sh
```

This will:
- ✅ Backup your database
- ✅ Apply schema changes
- ✅ Create sample coupon (GSPACES_DESKS_FOLLOW)
- ✅ Verify installation

### Step 2: Restart Application
```bash
sudo systemctl restart gspaces
# OR
pkill -f 'python.*main.py' && python main.py &
```

### Step 3: Test It!
1. Login to your site
2. Go to `/wallet`
3. Enter code: `GSPACES_DESKS_FOLLOW`
4. Click "Redeem"
5. ✅ ₹1000 added to wallet!

---

## 📋 What's New?

### For Users
- **Redeem Coupons**: Add money to wallet using coupon codes
- **One-Time Use**: Each coupon works once per user
- **Instant Credit**: Balance updates immediately
- **Transaction History**: See all redemptions

### For Admins
- **Coupon Types**: Order / Wallet / Both
- **Expiry Control**: Set expiry or make permanent
- **Private Coupons**: Assign to specific users
- **Usage Tracking**: See who used what

---

## 🎯 Common Use Cases

### 1. Instagram Follow Reward
**Scenario**: Reward users for following @gspaces_desks

**Setup**:
- Code: `GSPACES_DESKS_FOLLOW`
- Amount: ₹1000
- Type: Wallet
- Expiry: Non-Expiry
- ✅ Already created by migration!

### 2. Welcome Bonus
**Scenario**: Give new users ₹500

**Setup**:
1. Go to `/admin/coupons`
2. Add coupon:
   - Code: `WELCOME500`
   - Amount: 500
   - Type: Wallet
   - Expiry: Non-Expiry
3. Share with new users

### 3. Birthday Gift
**Scenario**: Give user ₹2000 on birthday

**Setup**:
1. Go to `/admin/coupons`
2. Add coupon:
   - Code: `BDAY_USER123`
   - Amount: 2000
   - Type: Wallet
   - User ID: 123 (private)
   - Valid Until: Birthday date
3. Email user the code

### 4. Promotional Campaign
**Scenario**: ₹300 off for first 100 users

**Setup**:
1. Create 100 unique codes
2. Set Type: Both (wallet or cart)
3. Set expiry: Campaign end date
4. Distribute via email/social media

---

## 🎨 Admin Panel Guide

### Creating Coupons

#### Public Wallet Coupon
```
Code: SAVE1000
Amount: 1000
Type: Wallet ← Important!
Expiry Type: Non-Expiry
User ID: (leave empty)
```

#### Private Wallet Coupon
```
Code: VIP2000
Amount: 2000
Type: Wallet
Expiry Type: Expiry
Valid Until: 2026-12-31
User ID: 456 ← Specific user
```

#### Flexible Coupon (Both)
```
Code: FLEX500
Amount: 500
Type: Both ← Can use in cart OR wallet
Expiry Type: Expiry
Valid Until: 2026-06-30
```

### Color Codes
- 🟢 **Green Badge** = Wallet only
- 🔵 **Blue Badge** = Order only
- 🟣 **Purple Badge** = Both types

---

## 👤 User Experience

### Redemption Flow
1. User goes to `/wallet`
2. Sees "Redeem Coupon Code" section
3. Enters code (auto-uppercase)
4. Clicks "Redeem"
5. Gets instant feedback:
   - ✅ Success: "₹1000 added to wallet!"
   - ❌ Error: Clear message why it failed

### Error Messages
| Message | Meaning | Solution |
|---------|---------|----------|
| "Invalid coupon code" | Doesn't exist | Check spelling |
| "Already used" | Used before | Can't reuse |
| "Expired" | Past date | Get new code |
| "Private coupon" | Not yours | Contact admin |
| "Cannot be used for wallet" | Order-only | Use in cart |

---

## 🔒 Security Features

### 1. One-Time Usage
- Each user can use coupon once
- Database constraint enforces this
- No workarounds possible

### 2. Private Coupons
- Bound to specific user ID
- Others can't use it
- Perfect for personalized gifts

### 3. Expiry Control
- Set expiry dates
- Or make permanent
- Auto-validation on redemption

### 4. Type Restrictions
- Wallet coupons only for wallet
- Order coupons only for cart
- "Both" type is flexible

---

## 📊 Tracking & Analytics

### View Usage
```sql
-- See all wallet redemptions
SELECT 
    cu.coupon_code,
    u.name,
    cu.discount_amount,
    cu.used_at
FROM coupon_usage cu
JOIN users u ON cu.user_id = u.id
WHERE cu.usage_type = 'wallet'
ORDER BY cu.used_at DESC;
```

### Popular Coupons
```sql
-- Most redeemed coupons
SELECT 
    coupon_code,
    COUNT(*) as redemptions,
    SUM(discount_amount) as total_amount
FROM coupon_usage
WHERE usage_type = 'wallet'
GROUP BY coupon_code
ORDER BY redemptions DESC;
```

---

## 🐛 Troubleshooting

### Issue: Coupon not working
**Check**:
1. Is it active? (is_active = true)
2. Is it expired? (check valid_until)
3. Already used? (check coupon_usage)
4. Right type? (coupon_type = 'wallet' or 'both')

### Issue: Balance not updating
**Check**:
1. Look at wallet_transactions table
2. Check user's wallet_balance
3. Review error logs
4. Verify database connection

### Issue: Can't create coupon
**Check**:
1. Code must be unique
2. Amount must be positive
3. Valid until must be future date (if expiry type)
4. User ID must exist (if private)

---

## 📱 Mobile Experience

The redemption UI is fully responsive:
- Large input field
- Easy-to-tap button
- Clear error messages
- Success animations

---

## 🔄 Rollback (If Needed)

If something goes wrong:

```bash
# Restore database
psql -U sri -d gspaces < backups_YYYYMMDD_HHMMSS/gspaces_backup.sql

# Restore files
cp backups_YYYYMMDD_HHMMSS/*.backup <original_location>

# Restart app
sudo systemctl restart gspaces
```

---

## 📚 Additional Resources

- **Full Guide**: `WALLET_COUPON_FEATURE_GUIDE.md`
- **Migration File**: `add_wallet_coupon_support.sql`
- **Deployment Script**: `deploy_wallet_coupon_feature.sh`

---

## ✅ Success Checklist

After deployment, verify:

- [ ] Can access `/wallet` page
- [ ] See "Redeem Coupon Code" section
- [ ] Can enter coupon code
- [ ] GSPACES_DESKS_FOLLOW works
- [ ] Balance increases correctly
- [ ] Transaction appears in history
- [ ] Can't use same coupon twice
- [ ] Admin panel shows coupon types
- [ ] Color badges display correctly
- [ ] Expired coupons show as expired

---

## 🎉 You're All Set!

The wallet coupon feature is now live. Users can:
- Redeem coupons for instant wallet credit
- See their transaction history
- Get clear feedback on redemptions

Admins can:
- Create flexible coupon types
- Set expiry rules
- Assign private coupons
- Track usage analytics

**Need help?** Check `WALLET_COUPON_FEATURE_GUIDE.md` for detailed documentation.