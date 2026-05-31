#!/bin/bash

# Sync Images to Server Script
# This uploads local images that are ignored by git

echo "📸 Syncing images to server..."

# Server details (update these)
SERVER_USER="ec2-user"
SERVER_HOST="your-server-ip"  # Replace with actual IP
SERVER_PATH="/home/ec2-user/gspaces"

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    echo "❌ rsync not found. Installing..."
    # For macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install rsync
    fi
fi

echo ""
echo "🔍 Images to sync:"
echo "  - static/img/icons/ (item icons)"
echo "  - static/img/Products/ (product images)"
echo ""

# Sync icons
echo "📤 Syncing icons..."
rsync -avz --progress static/img/icons/ ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/static/img/icons/

# Sync Products
echo "📤 Syncing product images..."
rsync -avz --progress static/img/Products/ ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/static/img/Products/

echo ""
echo "✅ Image sync complete!"
echo ""
echo "⚠️  IMPORTANT: Update SERVER_HOST in this script with your actual server IP"
echo "    Then run: ./sync_images_to_server.sh"

# Made with Bob
