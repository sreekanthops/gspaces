#!/bin/bash

# Deployment script for order management enhancements
# Run this on the EC2 server

echo "🚀 Deploying Order Management Enhancements..."

# Navigate to project directory
cd /var/www/gspaces || exit 1

# Pull latest changes from order branch
echo "📥 Pulling latest changes..."
git fetch origin
git checkout order
git pull origin order

# Restart the service
echo "🔄 Restarting gspaces service..."
sudo systemctl restart gspaces

# Check service status
echo "✅ Checking service status..."
sudo systemctl status gspaces --no-pager

echo ""
echo "✅ Deployment complete!"
echo "📧 Test by changing an order status to 'delivered'"

# Made with Bob
