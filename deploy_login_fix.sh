#!/bin/bash

# Deploy login form overlap fix to production server
# This script pulls the latest changes and restarts the application

echo "🚀 Deploying login form overlap fix..."

# Navigate to application directory
cd /var/www/gspaces || cd ~/gspaces || { echo "❌ Could not find gspaces directory"; exit 1; }

echo "📥 Pulling latest changes from blogs branch..."
git fetch origin
git checkout blogs
git pull origin blogs

echo "🔄 Restarting application..."

# Try different restart methods
if systemctl list-units --type=service | grep -q gspaces; then
    sudo systemctl restart gspaces
    echo "✅ Restarted gspaces service"
elif systemctl list-units --type=service | grep -q gunicorn; then
    sudo systemctl restart gunicorn
    echo "✅ Restarted gunicorn service"
elif [ -f "restart.sh" ]; then
    ./restart.sh
    echo "✅ Ran restart.sh"
else
    echo "⚠️  Please manually restart your Flask application"
fi

echo ""
echo "✅ Deployment complete!"
echo "🌐 Clear Cloudflare cache at: https://dash.cloudflare.com"
echo "🔄 Then hard refresh your browser (Ctrl+Shift+R)"

# Made with Bob
