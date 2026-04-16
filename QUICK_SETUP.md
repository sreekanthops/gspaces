# 🚀 One-Command Wallet Setup

## Super Simple Setup (Just Run This!)

```bash
./auto_setup_wallet.sh
```

That's it! The script will automatically:
- ✅ Backup your main.py
- ✅ Run database migration
- ✅ Add wallet imports
- ✅ Initialize wallet routes
- ✅ Integrate with signup
- ✅ Integrate with orders
- ✅ Verify everything works

## After Running the Script

**Restart your app:**
```bash
sudo systemctl restart gspaces
```

**Or if using a different method:**
```bash
# If using gunicorn
sudo systemctl restart gunicorn

# If running manually
pkill -f "python main.py"
python main.py &
```

## Test It Works

1. **Create a new user** - Should get ₹500 bonus
2. **Visit** http://your-server/wallet
3. **Check profile** - Should show wallet balance

## Verify Database

```bash
psql -U sri -d gspaces -c "SELECT id, name, wallet_balance, referral_code FROM users LIMIT 5;"
```

## If Something Goes Wrong

**Restore backup:**
```bash
cp backups_*/main.py.backup main.py
sudo systemctl restart gspaces
```

## What You Get

✅ ₹500 signup bonus (automatic)
✅ 5% first order cashback
✅ Unique referral codes
✅ 5% referral bonuses
✅ Wallet page at /wallet
✅ Transaction history
✅ Smart ₹10K limit per order

## Need Help?

Check the logs:
```bash
tail -f /var/log/gspaces/error.log
```

Or see detailed docs:
- WALLET_SYSTEM_README.md
- SERVER_DEPLOYMENT_STEPS.md

---

**That's it! Just run `./auto_setup_wallet.sh` and restart your app!** 🎉