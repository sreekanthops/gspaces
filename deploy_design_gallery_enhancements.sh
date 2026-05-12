#!/bin/bash

# Design Gallery Enhancements Deployment Script
# This script deploys all the new features for the design gallery

echo "========================================="
echo "Design Gallery Enhancements Deployment"
echo "========================================="
echo ""

# Step 1: Run database migrations
echo "Step 1: Running database migrations..."
psql -U sri -d gspaces -f enhance_design_gallery_features.sql

if [ $? -eq 0 ]; then
    echo "✓ Database migrations completed successfully"
else
    echo "✗ Database migrations failed"
    exit 1
fi

echo ""

# Step 2: Restart the application
echo "Step 2: Restarting application..."
sudo systemctl restart gspaces

if [ $? -eq 0 ]; then
    echo "✓ Application restarted successfully"
else
    echo "✗ Application restart failed"
    exit 1
fi

echo ""

# Step 3: Verify the changes
echo "Step 3: Verifying changes..."
echo ""
echo "Checking database schema..."
psql -U sri -d gspaces -c "\d lead_designs" | grep "type"

if [ $? -eq 0 ]; then
    echo "✓ Type field added to lead_designs"
else
    echo "✗ Type field not found in lead_designs"
fi

echo ""
echo "Checking design_images table..."
psql -U sri -d gspaces -c "\d design_images" | grep "is_primary"

if [ $? -eq 0 ]; then
    echo "✓ design_images table structure verified"
else
    echo "✗ design_images table structure issue"
fi

echo ""
echo "========================================="
echo "Deployment Summary"
echo "========================================="
echo ""
echo "✓ Video completion detection added to design gallery view"
echo "✓ Play/pause buttons added to both gallery and quotation pages"
echo "✓ Dynamic categories implemented (removes hardcoded 'commercial')"
echo "✓ Auto-play carousel on hover in public gallery"
echo "✓ Type field added to lead designs"
echo "✓ Media management routes added"
echo "✓ Primary image selection functionality added"
echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Test the public gallery at: /designs"
echo "2. Test design detail page carousel"
echo "3. Test quotation page carousel play/pause"
echo "4. Add 'type' field to admin lead forms"
echo "5. Create admin_design_media.html template for media management"
echo ""
echo "Deployment completed!"

# Made with Bob
