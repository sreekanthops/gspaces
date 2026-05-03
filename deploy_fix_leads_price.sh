#!/bin/bash

# Deploy script to fix missing price column in lead_designs table
# Run this on the server

echo "🔧 Fixing lead_designs table schema..."

# Add the price column
sudo -u sri psql -d gspaces -f fix_leads_price_column.sql

if [ $? -eq 0 ]; then
    echo "✅ Database schema fixed successfully"
    
    # Restart the application
    echo "🔄 Restarting application..."
    sudo systemctl restart python3
    
    echo "✅ Application restarted"
    echo ""
    echo "📊 Checking service status..."
    sudo systemctl status python3 --no-pager -l
else
    echo "❌ Failed to fix database schema"
    exit 1
fi

# Made with Bob
