#!/bin/bash

echo "Manual Carousel Fix - Step by Step"
echo "===================================="

# Step 1: Clean database
echo ""
echo "Step 1: Cleaning database..."
PGPASSWORD=gspaces2025 psql -U sri -d gspaces -h localhost << EOF
-- Show current images
SELECT 'BEFORE CLEANUP:' as status;
SELECT id, title, is_active, display_order FROM homepage_carousel_images ORDER BY display_order;

-- Delete inactive images
DELETE FROM homepage_carousel_images WHERE is_active = FALSE;

-- Reorder active images
UPDATE homepage_carousel_images SET display_order = 0 WHERE id = 3;
UPDATE homepage_carousel_images SET display_order = 1 WHERE id = 5;
UPDATE homepage_carousel_images SET display_order = 2 WHERE id = 6;

-- Show after cleanup
SELECT 'AFTER CLEANUP:' as status;
SELECT id, title, is_active, display_order, image_url FROM homepage_carousel_images ORDER BY display_order;
EOF

# Step 2: Clear cache
echo ""
echo "Step 2: Clearing cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Step 3: Restart app
echo ""
echo "Step 3: Restarting Flask..."
sudo systemctl restart gspaces
sleep 3
sudo systemctl status gspaces --no-pager | head -20

echo ""
echo "===================================="
echo "✅ Done! Now:"
echo "1. Hard refresh browser (Ctrl+Shift+R)"
echo "2. Or open in Incognito mode"
echo "3. Check browser console (F12) for errors"
echo "===================================="

# Made with Bob
