# Quick Deployment Instructions

## Simple Deployment (Recommended)

Since all changes are code-only (no database changes), just pull and restart:

```bash
# SSH to server
ssh ec2-user@13.233.212.175

# Navigate to project directory
cd /home/ec2-user/gspaces

# Pull latest changes
git pull origin main

# Restart application
sudo systemctl restart gspaces

# Check status
sudo systemctl status gspaces
```

That's it! ✅

## What Changed (Code Only)
1. `email_helper.py` - Fixed SMTP credentials
2. `main.py` - Added bonus coupons query to profile route
3. `admin_referral_routes.py` - Added email notifications for all changes
4. `templates/profile.html` - Added bonus coupons display section
5. `templates/admin_referral_coupons.html` - Added bonus coupons column

## No Database Changes Required
- Uses existing `coupons` table with `user_id` and `is_personal` columns
- Uses existing `referral_coupons` table
- No new tables, no schema changes

## Verify Deployment

### 1. Check Application is Running
```bash
sudo systemctl status gspaces
```

### 2. Check Bonus Coupons in Database
```bash
psql -U sri -d gspaces -c "SELECT code, user_id, is_personal FROM coupons WHERE is_personal = TRUE;"
```

### 3. Test in Browser
- Admin: https://gspaces.in/admin/referral-coupons
  - Look for "Bonus Coupons" column
- User: https://gspaces.in/profile
  - Go to Wallet tab
  - Look for "My Bonus Coupons" section

## Troubleshooting

### If Application Won't Start
```bash
# Check logs
sudo journalctl -u gspaces -f

# Common issues:
# - Syntax error in Python files
# - Missing dependencies
```

### If Bonus Coupons Don't Show
```bash
# Verify database has bonus coupons
psql -U sri -d gspaces -c "SELECT * FROM coupons WHERE is_personal = TRUE;"

# Clear browser cache
# Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
```

### If Emails Don't Send
```bash
# Check SMTP credentials in email_helper.py
grep -A 5 "SMTP_USERNAME" email_helper.py

# Should show:
# SMTP_USERNAME = os.getenv('MAIL_USERNAME', 'sri.chityala501@gmail.com')
# SMTP_PASSWORD = os.getenv('MAIL_PASSWORD', 'zupd zixc vvzp kptk')
```

## Rollback (If Needed)
```bash
# Go back to previous commit
git log --oneline  # Find previous commit hash
git reset --hard <previous-commit-hash>
sudo systemctl restart gspaces
```

---

**That's all you need!** Just `git pull` and `sudo systemctl restart gspaces` 🚀