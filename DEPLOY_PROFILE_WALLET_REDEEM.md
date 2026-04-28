# Deploy Wallet Redeem Coupon Section to Profile Page

## What Was Added

A beautiful **Redeem Coupon Code** section has been added to the Wallet tab in the user profile page.

### Features:
- ✅ Green gradient card design matching the modern UI
- ✅ Coupon code input field with auto-uppercase
- ✅ Redeem button with gift icon
- ✅ Flash message support for success/error feedback
- ✅ Instructions panel explaining the redemption process
- ✅ Warning note about verification requirements
- ✅ Fully responsive design

## Files Modified

1. **`templates/profile.html`** - Added redeem coupon section to wallet tab
2. **`wallet_routes.py`** - Fixed wallet route function name and added referral_benefits

## Deployment Steps

### Step 1: Pull Latest Changes

```bash
cd /path/to/your/gspaces/project
git pull origin wallet-coupon-feature
```

### Step 2: Verify Files Updated

```bash
# Check that profile.html was updated
grep -n "Redeem Coupon Code" templates/profile.html

# Check that wallet_routes.py was updated
grep -n "def wallet():" wallet_routes.py
```

### Step 3: Restart Flask Application

**Option A: Using systemd**
```bash
sudo systemctl restart gspaces
sudo systemctl status gspaces
```

**Option B: Using supervisor**
```bash
sudo supervisorctl restart gspaces
sudo supervisorctl status gspaces
```

**Option C: Manual restart**
```bash
# Kill the current process
pkill -f "python.*main.py"

# Start the application
python3 main.py
```

### Step 4: Clear Browser Cache

Users should clear their browser cache or do a hard refresh:
- **Chrome/Edge**: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
- **Firefox**: `Ctrl+F5` (Windows) or `Cmd+Shift+R` (Mac)
- **Safari**: `Cmd+Option+R` (Mac)

## Verification

1. **Navigate to Profile Page:**
   ```
   https://your-domain.com/profile
   ```

2. **Click on "Wallet" tab in the sidebar**

3. **You should now see:**
   - ✅ Wallet Balance card (purple gradient)
   - ✅ Wallet Benefits card
   - ✅ **Redeem Coupon Code card (green gradient)** ← NEW!
   - ✅ Refer Friends & Earn card (pink gradient)
   - ✅ My Bonus Coupons section (if applicable)
   - ✅ Recent Transactions table

4. **Test the Redeem Feature:**
   - Enter a coupon code (e.g., `GSPACES_DESKS_FOLLOW`)
   - Click "Redeem" button
   - Should see success/error message
   - Balance should update if coupon is valid

## Visual Design

The redeem section features:
- **Background**: Green gradient (`#11998e` to `#38ef7d`)
- **Layout**: Two-column responsive design
  - Left: Form with input and button
  - Right: Instructions panel
- **Input Field**: Large, rounded, with white background
- **Button**: White with bold text and gift icon
- **Alert Messages**: Bootstrap alerts with icons
- **Warning Note**: Semi-transparent box at bottom

## Route Information

The form submits to:
```
POST /wallet/redeem_coupon
```

This route is defined in `wallet_routes.py` and handles:
- Coupon validation
- User eligibility checks
- Balance updates
- Flash message feedback
- Redirect back to profile page

## Troubleshooting

### Issue: Section not visible after deployment
**Solution:**
1. Verify file was updated: `cat templates/profile.html | grep "Redeem Coupon"`
2. Restart Flask application
3. Clear browser cache (hard refresh)
4. Check browser console for errors

### Issue: Form submission fails
**Solution:**
1. Check Flask logs for errors
2. Verify route exists: `grep "redeem_wallet_coupon" wallet_routes.py`
3. Ensure database connection is working
4. Check `coupon_usage` table exists

### Issue: Flash messages not showing
**Solution:**
1. Verify Bootstrap JS is loaded
2. Check that `get_flashed_messages()` is working
3. Look for JavaScript errors in console

### Issue: Styling looks broken
**Solution:**
1. Verify Bootstrap 5 CSS is loaded
2. Check Bootstrap Icons are loaded
3. Clear browser cache completely
4. Inspect element to see if styles are applied

## Database Requirements

Ensure these tables exist:
- `coupons` - Stores coupon codes
- `coupon_usage` - Tracks redemptions
- `wallets` - User wallet balances
- `wallet_transactions` - Transaction history

## Security Notes

The redemption system validates:
- ✅ Coupon exists and is active
- ✅ Coupon type is 'wallet' or 'both'
- ✅ User hasn't used this coupon before
- ✅ Coupon hasn't expired
- ✅ Private coupons match user_id
- ✅ Special verification for Instagram coupons

## Support

If you encounter issues:
1. Check Flask application logs
2. Verify all files were updated correctly
3. Ensure database tables exist
4. Test with a valid coupon code
5. Check browser console for JavaScript errors

---

**Deployment Date:** 2026-04-28
**Status:** ✅ Ready for Production
**Branch:** wallet-coupon-feature