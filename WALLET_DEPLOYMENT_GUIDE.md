# Wallet System Deployment Guide

## Quick Start

To deploy the wallet system to your server with automatic backup and rollback capability:

```bash
./deploy_wallet_to_server.sh
```

That's it! The script handles everything automatically.

---

## What the Script Does

### 1. **Creates Automatic Backup**
- Backs up entire database before making any changes
- Stores backup in timestamped directory: `wallet_backup_YYYYMMDD_HHMMSS/`
- Backup file: `gspaces_pre_wallet.sql`

### 2. **Deploys Wallet System**
- Creates wallet tables (wallet_transactions, referral_coupons, coupon_usage)
- Adds wallet columns to users and orders tables
- Creates referral code generation functions
- Sets up indexes for performance

### 3. **Credits Signup Bonuses**
- Automatically adds ₹500 to all existing users
- Creates transaction records for each bonus
- Only credits users who haven't received bonus yet

### 4. **Creates Rollback Script**
- Generates `rollback_wallet.sh` in backup directory
- One command to undo all changes if needed

---

## Deployment Steps

### On Your Server:

1. **Pull latest code:**
   ```bash
   cd /path/to/gspaces
   git pull origin wallet
   ```

2. **Run deployment script:**
   ```bash
   ./deploy_wallet_to_server.sh
   ```

3. **Restart Flask application:**
   ```bash
   # If using systemd:
   sudo systemctl restart gspaces
   
   # Or if running manually:
   pkill -f "python.*main.py"
   python3 main.py &
   ```

4. **Test the wallet feature:**
   - Visit: http://your-server/profile
   - Click on "Wallet" tab
   - Verify balance shows ₹500
   - Check referral code is displayed
   - Verify transaction history shows welcome bonus

---

## Rollback (If Needed)

If something goes wrong, you can easily rollback:

```bash
cd wallet_backup_YYYYMMDD_HHMMSS/
./rollback_wallet.sh
```

This will:
- Remove all wallet tables
- Remove wallet columns from users/orders tables
- Restore database to pre-deployment state

---

## Files Included

### Deployment Files:
- `deploy_wallet_to_server.sh` - Main deployment script
- `add_wallet_system.sql` - SQL commands for wallet system
- `WALLET_DEPLOYMENT_GUIDE.md` - This guide

### Application Files:
- `main.py` - Updated with wallet data fetching
- `templates/profile.html` - Updated with wallet tab
- `wallet_system.py` - Wallet business logic
- `wallet_routes.py` - Wallet API routes

---

## Verification

After deployment, verify everything works:

### 1. Check Database:
```bash
psql -U sri -d gspaces -c "SELECT COUNT(*) FROM wallet_transactions;"
psql -U sri -d gspaces -c "SELECT id, name, wallet_balance FROM users LIMIT 5;"
```

### 2. Check Application:
- Login to your account
- Go to Profile page
- Click "Wallet" tab
- Should see:
  - ₹500 balance
  - Your referral code
  - Welcome bonus transaction

### 3. Check Logs:
```bash
# Check for any errors
tail -f /path/to/your/flask.log
```

---

## Troubleshooting

### Issue: "Wallet tables already exist"
**Solution:** The script will ask if you want to continue. Say "yes" to skip table creation and just credit bonuses.

### Issue: "Permission denied"
**Solution:** Make script executable:
```bash
chmod +x deploy_wallet_to_server.sh
```

### Issue: "Database connection failed"
**Solution:** Check PostgreSQL is running:
```bash
sudo systemctl status postgresql
```

### Issue: "Wallet tab is empty"
**Solution:** 
1. Hard refresh browser (Ctrl+Shift+R)
2. Check Flask app restarted after deployment
3. Check browser console for JavaScript errors

---

## Safety Features

✅ **Automatic Backup** - Full database backup before any changes
✅ **Rollback Script** - One-command rollback if needed
✅ **Idempotent** - Safe to run multiple times
✅ **Verification** - Checks deployment success
✅ **Error Handling** - Stops on any error

---

## What Gets Backed Up

The backup includes:
- All tables and data
- All functions and triggers
- All indexes and constraints
- Complete database schema

Backup location: `wallet_backup_YYYYMMDD_HHMMSS/gspaces_pre_wallet.sql`

---

## Support

If you encounter any issues:

1. Check the deployment summary: `wallet_backup_*/deployment_summary.txt`
2. Review backup directory for rollback script
3. Check Flask application logs
4. Verify PostgreSQL is running

---

## Post-Deployment

After successful deployment:

1. ✅ Keep backup directory safe (don't delete for at least 7 days)
2. ✅ Monitor application logs for any errors
3. ✅ Test wallet features thoroughly
4. ✅ Inform users about new wallet feature

---

## Quick Reference

```bash
# Deploy wallet system
./deploy_wallet_to_server.sh

# Rollback if needed
cd wallet_backup_YYYYMMDD_HHMMSS/
./rollback_wallet.sh

# Check wallet data
psql -U sri -d gspaces -c "SELECT * FROM wallet_transactions LIMIT 5;"

# Restart Flask
sudo systemctl restart gspaces
```

---

**Note:** The deployment script is designed to be safe and reversible. Always keep the backup directory until you're confident the deployment is stable.