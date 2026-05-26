#!/bin/bash

echo "🚀 Deploying Cost Analysis Feature..."

# Pull latest changes
echo "📥 Pulling latest code..."
git pull origin order

# Restart Flask application
echo "🔄 Restarting Flask application..."
sudo systemctl restart gspaces

# Wait for service to start
sleep 3

# Check if service is running
if sudo systemctl is-active --quiet gspaces; then
    echo "✅ Flask application restarted successfully!"
else
    echo "❌ Failed to restart Flask application"
    sudo systemctl status gspaces
    exit 1
fi

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Clear your browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)"
echo "2. Or do a hard refresh (Ctrl+F5 or Cmd+Shift+R)"
echo "3. Go to quotation page and check the Cost Analysis section"
echo ""
echo "The cost price fields should now be empty (not showing ₹480)"
echo "The 'Manage Cost Prices' button should be removed"

# Made with Bob
