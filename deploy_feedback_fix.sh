#!/bin/bash

echo "🔄 Deploying Quotation Feedback Fix..."

# Restart the application
echo "Restarting gspaces service..."
sudo systemctl restart gspaces

# Wait for service to start
sleep 3

# Check status
echo "Checking service status..."
sudo systemctl status gspaces --no-pager | head -20

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Clear browser cache (Ctrl+Shift+Delete)"
echo "2. Hard refresh the quotation page (Ctrl+Shift+R)"
echo "3. Check browser console - 'None is not defined' error should be gone"
echo "4. Test clicking stars - should work now"

# Made with Bob
