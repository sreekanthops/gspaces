#!/bin/bash

# Deploy Leads Quotation Fixes
# This script fixes the issue where new fields are not showing in quotation page
# and adds default items to the database

echo "=========================================="
echo "Deploying Leads Quotation Fixes"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Database credentials
DB_NAME="gspaces"
DB_USER="sri"

echo -e "${YELLOW}Step 1: Adding missing default items to database...${NC}"
sudo -u postgres psql -U $DB_USER -d $DB_NAME -f add_missing_default_items.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Default items added successfully${NC}"
else
    echo -e "${RED}✗ Failed to add default items${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Restarting application...${NC}"
systemctl restart gspaces
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Application restarted successfully${NC}"
else
    echo -e "${RED}✗ Failed to restart application${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo "==========================================${NC}"
echo ""
echo "Changes made:"
echo "1. ✓ Added multi_socket, desk_lamp, pen_holder, laptop_holder to default_items"
echo "2. ✓ Updated quotation template to use descriptions from default_items table"
echo "3. ✓ Fixed icons for new items (using render_icon macro)"
echo ""
echo "Next steps:"
echo "1. Test by editing a lead and adding new items"
echo "2. View the quotation page to verify new items appear"
echo "3. Check that descriptions are pulled from default_items table"
echo ""
echo "If items still don't show:"
echo "- Check if has_multi_socket, has_desk_lamp, etc. are set to TRUE in lead_designs"
echo "- Verify the items have quantity > 0"
echo "- Check browser console for any JavaScript errors"

# Made with Bob
