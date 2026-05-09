#!/bin/bash

# Deployment script for admin panel styling fixes
# This script updates the production server with the latest changes

echo "🚀 Deploying Admin Panel Styling Fixes..."
echo "=========================================="

# Navigate to production directory
cd /var/www/gspaces || exit 1

echo "📥 Fetching latest changes from optimise branch..."
git fetch origin optimise

echo "🔄 Checking out optimise branch..."
git checkout optimise

echo "⬇️  Pulling latest changes..."
git pull origin optimise

echo "🔄 Restarting GSpaces service..."
sudo systemctl restart gspaces

echo "✅ Checking service status..."
sudo systemctl status gspaces --no-pager

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo ""
echo "Changes applied:"
echo "  - Removed violet background color"
echo "  - Fixed container width and padding"
echo "  - Maintained premium card designs"
echo "  - Seamless sidebar integration"
echo ""
echo "Please refresh your browser to see the changes."
echo "Clear browser cache if needed: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"

# Made with Bob
