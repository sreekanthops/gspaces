#!/bin/bash

echo "🔧 Fixing Wallet Balances and Template Issues"
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 0: Pull latest changes from wallet branch
echo -e "\n${YELLOW}Step 0: Pulling latest changes from wallet branch...${NC}"
git fetch origin
git checkout wallet
git pull origin wallet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully pulled from wallet branch${NC}"
else
    echo -e "${RED}❌ Failed to pull from wallet branch${NC}"
    exit 1
fi

# Step 1: Fix wallet balances
echo -e "\n${YELLOW}Step 1: Fixing wallet balances...${NC}"
psql -U sri -d gspaces -f fix_wallet_sync.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Wallet balances updated successfully${NC}"
else
    echo -e "${RED}❌ Failed to update wallet balances${NC}"
    exit 1
fi

# Step 2: Copy updated template
echo -e "\n${YELLOW}Step 2: Deploying updated admin template...${NC}"
if [ -f "templates/admin_referral_coupons.html" ]; then
    echo -e "${GREEN}✅ Template file found${NC}"
else
    echo -e "${RED}❌ Template file not found${NC}"
    exit 1
fi

# Step 3: Restart the application
echo -e "\n${YELLOW}Step 3: Restarting GSpaces application...${NC}"
sudo systemctl restart gspaces

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Application restarted successfully${NC}"
else
    echo -e "${RED}❌ Failed to restart application${NC}"
    exit 1
fi

# Step 4: Check service status
echo -e "\n${YELLOW}Step 4: Checking service status...${NC}"
sleep 2
sudo systemctl status gspaces --no-pager | head -n 10

echo -e "\n${GREEN}=============================================="
echo -e "✅ All fixes applied successfully!"
echo -e "=============================================="
echo -e "${NC}"
echo "Next steps:"
echo "1. Visit: http://your-server-ip/admin/referral-coupons"
echo "2. Check that wallet balances now show ₹500.00"
echo "3. Test the 💰 Adjust button - it should open a modal"
echo "4. No JavaScript code should be visible on the page"
echo ""
echo "If you still see issues, check the browser console (F12) for errors."

# Made with Bob
