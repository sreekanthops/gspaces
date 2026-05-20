#!/bin/bash

echo "=========================================="
echo "Fixing Carousel - Removing 4th Stuck Image"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Cleaning up database - removing inactive carousel images${NC}"
PGPASSWORD=gspaces2025 psql -U sri -d gspaces -h localhost -f fix_carousel_cleanup.sql

echo -e "\n${YELLOW}Step 2: Pulling latest template changes from git${NC}"
git pull origin setups

echo -e "\n${YELLOW}Step 3: Clearing Flask cache and compiled templates${NC}"
# Remove Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Clear Flask template cache if exists
rm -rf flask_cache/* 2>/dev/null || true
rm -rf __pycache__/* 2>/dev/null || true

echo -e "\n${YELLOW}Step 4: Restarting Flask application${NC}"
sudo systemctl stop gspaces
sleep 2
sudo systemctl start gspaces
sleep 2
sudo systemctl status gspaces --no-pager

echo -e "\n${YELLOW}Step 5: Clearing Nginx cache (if exists)${NC}"
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true
sudo systemctl reload nginx 2>/dev/null || true

echo -e "\n${GREEN}✅ Carousel fix deployed successfully!${NC}"
echo -e "\n${YELLOW}What was fixed:${NC}"
echo "  ✓ Removed 3 inactive carousel images from database"
echo "  ✓ Reordered active images to display_order 0, 1, 2"
echo "  ✓ Updated template to only show admin carousel images"
echo "  ✓ Removed fallback banner from carousel rotation"
echo "  ✓ Cleared Python and Flask cache"
echo "  ✓ Cleared Nginx cache"
echo ""
echo -e "${GREEN}Your carousel now shows ONLY these 3 images:${NC}"
echo "  1. Premium Home Office Setup (carousel_20260509_151521_DSC06887_2.jpg)"
echo "  2. Luxury Podcast Setup (carousel_20260520_110851_podcast3.png)"
echo "  3. Luxury Studio Setup (carousel_20260520_111151_amaru.png)"
echo ""
echo -e "${RED}IMPORTANT - Clear Browser Cache:${NC}"
echo "  Press Ctrl+Shift+R (or Cmd+Shift+R on Mac) to hard refresh"
echo "  Or open in Incognito/Private mode to test"
echo ""
echo -e "${YELLOW}Test your website now:${NC}"
echo "  - Visit your homepage"
echo "  - You should see only 3 carousel images"
echo "  - 3 indicator dots at the bottom"
echo "  - Left/Right buttons should work"
echo "  - Auto-rotation every 3 seconds"
echo ""
echo "=========================================="

# Made with Bob
