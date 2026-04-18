#!/bin/bash

# Deployment Script for Bonus Coupon Feature
# This script deploys all bonus coupon improvements to the server

set -e  # Exit on error

echo "=========================================="
echo "Bonus Coupon Feature Deployment"
echo "=========================================="
echo ""

# Configuration
SERVER_USER="ec2-user"
SERVER_HOST="13.233.212.175"
SERVER_PATH="/home/ec2-user/gspaces"
DB_NAME="gspaces"
DB_USER="sri"

echo "📋 Deployment Summary:"
echo "  - Fixed SMTP credentials in email_helper.py"
echo "  - Added bonus coupons display in user profile/wallet"
echo "  - Added 'Bonus Coupons' column in admin referral page"
echo "  - Added email notifications for ALL user changes"
echo ""

# Step 1: Backup current files on server
echo "Step 1: Creating backup on server..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces
mkdir -p backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)
cp main.py backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)/
cp email_helper.py backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)/
cp admin_referral_routes.py backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)/
cp templates/profile.html backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)/
cp templates/admin_referral_coupons.html backups_bonus_coupons_$(date +%Y%m%d_%H%M%S)/
echo "✅ Backup created"
ENDSSH

# Step 2: Upload updated files
echo ""
echo "Step 2: Uploading updated files..."
scp email_helper.py ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/
scp main.py ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/
scp admin_referral_routes.py ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/
scp templates/profile.html ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/templates/
scp templates/admin_referral_coupons.html ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/templates/
echo "✅ Files uploaded"

# Step 3: Restart the application
echo ""
echo "Step 3: Restarting application..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces
sudo systemctl restart gspaces
sleep 3
sudo systemctl status gspaces --no-pager
echo "✅ Application restarted"
ENDSSH

# Step 4: Verify deployment
echo ""
echo "Step 4: Verifying deployment..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces

# Check if files exist
echo "Checking files..."
[ -f "email_helper.py" ] && echo "  ✅ email_helper.py exists"
[ -f "main.py" ] && echo "  ✅ main.py exists"
[ -f "admin_referral_routes.py" ] && echo "  ✅ admin_referral_routes.py exists"
[ -f "templates/profile.html" ] && echo "  ✅ templates/profile.html exists"
[ -f "templates/admin_referral_coupons.html" ] && echo "  ✅ templates/admin_referral_coupons.html exists"

# Check application status
echo ""
echo "Application status:"
sudo systemctl is-active gspaces && echo "  ✅ Application is running" || echo "  ❌ Application is not running"

# Check database for bonus coupons
echo ""
echo "Checking database for bonus coupons..."
psql -U sri -d gspaces -c "SELECT COUNT(*) as bonus_coupon_count FROM coupons WHERE is_personal = TRUE;" 2>/dev/null || echo "  ⚠️  Could not query database (may need manual check)"

ENDSSH

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📝 What was deployed:"
echo "  1. Fixed SMTP credentials (using existing credentials from main.py)"
echo "  2. Added bonus coupons section in user profile/wallet page"
echo "  3. Added 'Bonus Coupons' column in admin referral management page"
echo "  4. Added email notifications for:"
echo "     - Referral coupon updates"
echo "     - Wallet adjustments"
echo "     - Bonus coupon creation"
echo ""
echo "🧪 Testing checklist:"
echo "  [ ] Login to admin panel: https://gspaces.in/admin/referral-coupons"
echo "  [ ] Verify 'Bonus Coupons' column shows existing bonus coupons"
echo "  [ ] Edit a user's referral settings and check email notification"
echo "  [ ] Create a bonus coupon for a user and verify:"
echo "      - Coupon appears in 'Bonus Coupons' column"
echo "      - User receives email notification"
echo "      - Coupon appears in user's profile/wallet page"
echo "  [ ] Login as regular user and check profile/wallet page"
echo "  [ ] Verify bonus coupons are displayed with copy button"
echo "  [ ] Test copying bonus coupon code"
echo "  [ ] Apply bonus coupon in cart and verify it works"
echo ""
echo "📧 Email notifications now sent for:"
echo "  ✅ Bonus coupon creation"
echo "  ✅ Referral coupon updates (Friend Gets / Owner Gets changes)"
echo "  ✅ Wallet balance adjustments"
echo ""
echo "🔍 Troubleshooting:"
echo "  - If emails not sending, check SMTP credentials in email_helper.py"
echo "  - If bonus coupons not showing, check database: SELECT * FROM coupons WHERE is_personal = TRUE;"
echo "  - Check application logs: sudo journalctl -u gspaces -f"
echo ""
echo "🎉 All bonus coupon improvements are now live!"
echo ""

# Made with Bob
