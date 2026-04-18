#!/bin/bash

# Server-Side Deployment Script for Wallet Adjustment Feature
# Run this script ON THE SERVER as ec2-user

echo "=========================================="
echo "Wallet Adjustment Feature Deployment"
echo "=========================================="
echo ""

# Navigate to project directory
cd /home/ec2-user/gspaces

echo "📥 Step 1: Pulling latest changes from wallet branch..."
git fetch origin
git checkout wallet
git pull origin wallet

if [ $? -eq 0 ]; then
    echo "✅ Code updated successfully"
else
    echo "❌ Failed to pull changes"
    exit 1
fi

echo ""
echo "🔄 Step 2: Restarting Flask application..."
sudo systemctl restart gspaces

if [ $? -eq 0 ]; then
    echo "✅ Application restarted successfully"
else
    echo "❌ Failed to restart application"
    exit 1
fi

echo ""
echo "📊 Step 3: Checking service status..."
sudo systemctl status gspaces --no-pager -l

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "=========================================="
echo ""
echo "🎉 Wallet adjustment feature is now live!"
echo ""
echo "📝 What was deployed:"
echo "   ✓ Wallet adjustment fields in Edit modal"
echo "   ✓ Current balance display"
echo "   ✓ Backend logic to ADD amount to balance"
echo "   ✓ Wallet transaction recording"
echo "   ✓ Email notifications"
echo ""
echo "🧪 Quick Test:"
echo "   1. Go to: https://gspaces.in/admin/referral-coupons"
echo "   2. Click 'Edit' on any referral coupon"
echo "   3. Scroll to 'Wallet Balance Update' section"
echo "   4. Enter amount and reason, then click 'Update Coupon'"
echo ""
echo "🔍 Monitor logs:"
echo "   sudo journalctl -u gspaces -f"
echo ""

# Made with Bob
