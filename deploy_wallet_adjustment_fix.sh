#!/bin/bash

# Deployment Script for Wallet Adjustment Feature
# This script deploys the integrated wallet adjustment feature to the server

echo "=========================================="
echo "Wallet Adjustment Feature Deployment"
echo "=========================================="
echo ""

# Configuration
SERVER_USER="ec2-user"
SERVER_HOST="13.127.245.37"
SERVER_PATH="/home/ec2-user/gspaces"
BRANCH="wallet"

echo "📋 Deployment Configuration:"
echo "   Server: $SERVER_USER@$SERVER_HOST"
echo "   Path: $SERVER_PATH"
echo "   Branch: $BRANCH"
echo ""

# Step 1: Commit and push changes
echo "Step 1: Committing and pushing changes to GitHub..."
git add templates/admin_referral_coupons.html
git add admin_referral_routes.py
git commit -m "Integrate wallet adjustment into Edit form - use standard POST instead of AJAX

Changes:
- Added wallet adjustment fields to Edit modal (wallet_adjustment, wallet_reason)
- Updated editCoupon() JavaScript to populate current balance
- Modified /admin/referral-coupons/update route to handle wallet adjustments
- Wallet adjustment ADDS to current balance (not replaces)
- Creates wallet transaction record with type 'admin_credit' or 'admin_debit'
- Sends email notification with correct parameters
- Shows success message with new balance

This approach uses standard form submission instead of AJAX for better reliability."

git push origin $BRANCH

if [ $? -eq 0 ]; then
    echo "✅ Changes pushed to GitHub successfully"
else
    echo "❌ Failed to push changes to GitHub"
    exit 1
fi

echo ""

# Step 2: Deploy to server
echo "Step 2: Deploying to server..."
ssh $SERVER_USER@$SERVER_HOST << 'ENDSSH'
    cd /home/ec2-user/gspaces
    
    echo "📥 Pulling latest changes from wallet branch..."
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
    echo "🔄 Restarting Flask application..."
    sudo systemctl restart gspaces
    
    if [ $? -eq 0 ]; then
        echo "✅ Application restarted successfully"
    else
        echo "❌ Failed to restart application"
        exit 1
    fi
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "📊 Service Status:"
    sudo systemctl status gspaces --no-pager -l
ENDSSH

if [ $? -eq 0 ]; then
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
    echo "🧪 Testing Instructions:"
    echo "   1. Go to: https://gspaces.in/admin/referral-coupons"
    echo "   2. Click 'Edit' on any referral coupon"
    echo "   3. Scroll to 'Wallet Balance Update' section"
    echo "   4. Enter amount to add (e.g., 100)"
    echo "   5. Enter reason (e.g., 'Test adjustment')"
    echo "   6. Click 'Update Coupon'"
    echo "   7. Verify success message shows new balance"
    echo "   8. Check user's wallet balance in profile"
    echo "   9. Verify email notification was sent"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   - Check logs: sudo journalctl -u gspaces -f"
    echo "   - Verify database: psql -U sri -d gspaces"
    echo "   - Check wallet_transactions table for new records"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ DEPLOYMENT FAILED"
    echo "=========================================="
    echo ""
    echo "Please check the error messages above and try again."
    exit 1
fi

# Made with Bob
