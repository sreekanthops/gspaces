#!/bin/bash

# Design Gallery Deployment Script
echo "🎨 Deploying Design Gallery Feature..."

# Navigate to project directory
cd /var/www/gspaces || exit 1

# Remove conflicting untracked file if it exists
if [ -f "fix_design_gallery_images.sql" ]; then
    echo "Removing existing fix_design_gallery_images.sql..."
    rm -f fix_design_gallery_images.sql
fi

# Checkout designs branch
echo "Checking out designs branch..."
git checkout designs

# Pull latest changes
echo "Pulling latest changes..."
git pull origin designs

# Create designs directory if it doesn't exist
echo "Creating designs directory..."
mkdir -p static/img/designs
chmod 755 static/img/designs

# Run database migrations
echo "Running database setup..."
psql -U sri -d gspaces -f create_design_gallery_table.sql

# Fix images with placeholders
echo "Updating images with placeholders..."
psql -U sri -d gspaces -f fix_design_gallery_images.sql

# Restart application
echo "Restarting application..."
sudo systemctl restart gspaces

echo "✅ Design Gallery deployed successfully!"
echo ""
echo "📍 Visit: https://yourdomain.com/designs"
echo "🔧 Admin: https://yourdomain.com/admin/design-gallery"

# Made with Bob
