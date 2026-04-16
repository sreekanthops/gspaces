# Server Deployment Steps for Wallet System

## Your Current Setup
- App is running on server: **13.51.205.239**
- Database: PostgreSQL on localhost
- Branch: **wallet** (already pushed to GitHub)

## Quick Deployment Steps

### Step 1: SSH into Your Server

```bash
ssh sri@13.51.205.239
# Or however you normally access your server
```

### Step 2: Navigate to Your App Directory

```bash
cd /path/to/gspaces  # Replace with your actual path
```

### Step 3: Pull the Wallet Branch

```bash
# Fetch latest changes
git fetch origin

# Switch to wallet branch
git checkout wallet

# Or if you want to merge into main:
# git checkout main
# git merge wallet
```

### Step 4: Run Database Migration

```bash
# Run the migration script
psql -U sri -d gspaces -f add_wallet_system.sql

# Verify tables were created
psql -U sri -d gspaces -c "\dt wallet_transactions"
psql -U sri -d gspaces -c "\dt referral_coupons"
psql -U sri -d gspaces -c "\dt coupon_usage"
```

### Step 5: Update main.py

You need to add these lines to main.py:

**At the top (after other imports, around line 46):**
```python
# Wallet system imports
from wallet_system import WalletSystem
from wallet_routes import add_wallet_routes, integrate_wallet_with_signup, integrate_wallet_with_order
```

**After app initialization (around line 115):**
```python
# Initialize wallet routes
add_wallet_routes(app, connect_to_db)
```

**In signup function (around line 445, after user creation):**
```python
# Credit signup bonus
integrate_wallet_with_signup(cursor, conn, user_id, name)
```

**In payment_success function (around line 2491, after cart deletion):**
```python
# Integrate wallet system
wallet_amount_used = Decimal(str(data.get('wallet_amount_used', 0)))
referral_code_used = data.get('referral_code_used')

integrate_wallet_with_order(
    conn=conn,
    user_id=current_user.id,
    order_id=new_order_id,
    order_amount=final_total,
    wallet_amount_used=wallet_amount_used,
    referral_code_used=referral_code_used
)
```

### Step 6: Restart Your Flask App

```bash
# If using systemd
sudo systemctl restart gspaces

# Or if using supervisor
sudo supervisorctl restart gspaces

# Or if running with gunicorn
sudo systemctl restart gunicorn

# Or if running manually, stop and start:
# pkill -f "python main.py"
# python main.py &
```

### Step 7: Verify Deployment

```bash
# Check if app is running
curl http://localhost:5000/

# Check wallet API endpoint
curl http://localhost:5000/api/wallet/balance

# Check logs
tail -f /var/log/gspaces/error.log  # Adjust path as needed
```

## Alternative: Quick Integration Script

If you want to automate the main.py changes, run this on your server:

```bash
cd /path/to/gspaces

# Backup main.py first
cp main.py main.py.backup

# Then manually edit main.py or use the integration guide
nano main.py  # or vim main.py
```

## Testing After Deployment

1. **Test Signup Bonus:**
   ```bash
   # Create a new user and check if ₹500 is credited
   psql -U sri -d gspaces -c "SELECT id, name, wallet_balance FROM users ORDER BY id DESC LIMIT 1;"
   ```

2. **Test Referral Code:**
   ```bash
   # Check if referral codes were generated
   psql -U sri -d gspaces -c "SELECT user_id, coupon_code FROM referral_coupons LIMIT 5;"
   ```

3. **Test Wallet Transactions:**
   ```bash
   # Check transaction history
   psql -U sri -d gspaces -c "SELECT * FROM wallet_transactions ORDER BY created_at DESC LIMIT 10;"
   ```

## Rollback Plan (If Needed)

If something goes wrong:

```bash
# Switch back to main branch
git checkout main

# Restore main.py backup
cp main.py.backup main.py

# Restart app
sudo systemctl restart gspaces

# Optionally, rollback database (only if needed)
# psql -U sri -d gspaces -c "DROP TABLE wallet_transactions CASCADE;"
# psql -U sri -d gspaces -c "DROP TABLE referral_coupons CASCADE;"
# psql -U sri -d gspaces -c "DROP TABLE coupon_usage CASCADE;"
```

## What You'll Get After Deployment

✅ New users get ₹500 signup bonus automatically
✅ First order gets 5% cashback
✅ Each user has a unique referral code
✅ Referral bonuses work automatically
✅ Wallet page accessible at: http://13.51.205.239/wallet
✅ API endpoints for wallet operations

## Monitoring

After deployment, monitor these:

```bash
# Check wallet balances
psql -U sri -d gspaces -c "SELECT SUM(wallet_balance) as total_liability FROM users;"

# Check recent transactions
psql -U sri -d gspaces -c "SELECT COUNT(*), transaction_type FROM wallet_transactions GROUP BY transaction_type;"

# Check referral usage
psql -U sri -d gspaces -c "SELECT COUNT(*) as active_referrals FROM referral_coupons WHERE is_active = TRUE;"
```

## Need Help?

If you encounter issues:
1. Check error logs
2. Verify database connection
3. Ensure all Python dependencies are installed
4. Check if wallet_system.py and wallet_routes.py are in the correct directory

## Summary

**Minimum steps to get wallet features:**
1. SSH to server
2. `git checkout wallet`
3. Run database migration
4. Add 3 import lines to main.py
5. Add 1 line to initialize routes
6. Add 2 integration calls (signup & payment)
7. Restart app

**Time required:** 10-15 minutes

All the code is ready - you just need to deploy it! 🚀