#!/bin/bash

# Deploy referral coupons admin page fix to server

echo "🚀 Deploying referral coupons admin page fix..."

# SSH into server and deploy
ssh root@139.59.77.175 << 'ENDSSH'
    cd /root/gspaces
    
    echo "📥 Pulling latest changes from wallet branch..."
    git fetch origin
    git checkout wallet
    git pull origin wallet
    
    echo "🔄 Restarting application..."
    sudo systemctl restart gspaces
    
    echo "✅ Deployment complete!"
    echo ""
    echo "Changes deployed:"
    echo "- Added Expires column to referral coupons table"
    echo "- Added Actions column with Edit and Deactivate buttons"
    echo ""
    echo "Please refresh your browser to see the changes."
ENDSSH

echo ""
echo "✅ Deployment script completed!"
echo "The referral coupons page should now show:"
echo "  - Expires column"
echo "  - Actions column with Edit and Deactivate buttons"

# Made with Bob
