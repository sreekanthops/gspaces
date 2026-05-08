#!/bin/bash

# Deployment script for Homepage Banner Management System
# This script sets up the database and deploys the homepage banner feature

echo "🚀 Starting Homepage Banner System Deployment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Database credentials
DB_NAME="gspaces"
DB_USER="postgres"

echo -e "${YELLOW}📊 Step 1: Creating homepage_banner table...${NC}"
sudo -u postgres psql -d $DB_NAME -f create_homepage_banner_table.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database table created successfully${NC}"
else
    echo -e "${RED}❌ Error creating database table${NC}"
    exit 1
fi

echo -e "${YELLOW}🔄 Step 2: Restarting GSpaces service...${NC}"
sudo systemctl restart gspaces

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Service restarted successfully${NC}"
else
    echo -e "${RED}❌ Error restarting service${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Step 3: Checking service status...${NC}"
sudo systemctl status gspaces --no-pager | head -n 10

echo ""
echo -e "${GREEN}✨ Deployment Complete!${NC}"
echo ""
echo "📝 Next Steps:"
echo "1. Visit: https://gspaces.in/admin/homepage-banner"
echo "2. Upload a new banner image (recommended: 1920x1080px)"
echo "3. Update title, subtitle, and button text as needed"
echo "4. Click 'Save Changes'"
echo "5. Visit homepage to see the new banner"
echo ""
echo "🎯 Features:"
echo "- Admin can upload custom banner images"
echo "- Customize title, subtitle, and button text"
echo "- Add YouTube video link"
echo "- Changes reflect immediately on homepage"
echo ""
echo -e "${YELLOW}⚠️  Note: Make sure to upload high-quality images for best results${NC}"

# Made with Bob
