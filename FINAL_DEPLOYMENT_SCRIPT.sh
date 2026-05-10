#!/bin/bash

# Final Deployment Script for Design Gallery with Customer Designs
echo "🎨 Deploying Design Gallery with Customer Designs..."

# Navigate to project directory
cd /var/www/gspaces || exit 1

# Pull latest code
echo "📥 Pulling latest code..."
git checkout designs
git pull origin designs

# Run database migrations
echo "🗄️ Running database migrations..."

# 1. Add video support
echo "🎬 Adding video support..."
psql -U sri -d gspaces -f add_video_support.sql

# 2. Sync customer designs with all media
echo "🔄 Syncing customer designs with all media..."
psql -U sri -d gspaces -f sync_customer_designs_with_media.sql

# 3. Update sync trigger for future designs
echo "🔄 Updating sync trigger for multiple media..."
psql -U sri -d gspaces -f update_sync_trigger_for_multiple_images.sql

# Restart application
echo "🔄 Restarting application..."
sudo systemctl restart gspaces
sudo systemctl status gspaces

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📍 What you get:"
echo "   - 2 customer designs synced"
echo "   - GreenNest Studio (3 media: 2 images + 1 video)"
echo "   - Dark Warm Ambient (2 media: 1 image + 1 video)"
echo "   - Auto-slide through all media (5 second interval)"
echo "   - Media count in slider (2/3, 1/2)"
echo "   - Image count badges in gallery (🖼️ 3, 🖼️ 2)"
echo "   - Category filters work"
echo "   - Videos play with controls"
echo ""
echo "📌 Admin Panel: Review and manage designs"
echo "🌐 Public Gallery: /designs"
echo ""
echo "Future customer designs will auto-sync with all their media!"

# Made with Bob
