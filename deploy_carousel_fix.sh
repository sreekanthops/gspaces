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
sudo -u postgres psql -d gspaces -f fix_carousel_cleanup.sql

echo -e "\n${YELLOW}Step 2: Pulling latest template changes from git${NC}"
git pull origin setups

echo -e "\n${YELLOW}Step 3: Restarting Flask application${NC}"
sudo systemctl restart gspaces

echo -e "\n${GREEN}✅ Carousel fix deployed successfully!${NC}"
echo -e "\n${YELLOW}What was fixed:${NC}"
echo "  ✓ Removed 3 inactive carousel images from database"
echo "  ✓ Reordered active images to display_order 0, 1, 2"
echo "  ✓ Updated template to only show admin carousel images"
echo "  ✓ Removed fallback banner from carousel rotation"
echo ""
echo -e "${GREEN}Your carousel now shows ONLY these 3 images:${NC}"
echo "  1. Premium Home Office Setup (carousel_20260509_151521_DSC06887_2.jpg)"
echo "  2. Luxury Podcast Setup (carousel_20260520_110851_podcast3.png)"
echo "  3. Luxury Studio Setup (carousel_20260520_111151_amaru.png)"
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
