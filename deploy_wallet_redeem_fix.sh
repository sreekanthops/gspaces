#!/bin/bash

# Deploy Wallet Redeem Coupon Fix
# This script fixes the wallet page to show the redeem coupon section

echo "=========================================="
echo "Deploying Wallet Redeem Coupon Fix"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup current file
echo -e "${YELLOW}Creating backup...${NC}"
cp wallet_routes.py wallet_routes.py.backup_$(date +%Y%m%d_%H%M%S)

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup created successfully${NC}"
else
    echo -e "${RED}✗ Backup failed${NC}"
    exit 1
fi

# The fix has already been applied to wallet_routes.py
# Just need to restart the application

echo ""
echo -e "${YELLOW}Restarting Flask application...${NC}"
echo "Please run one of the following commands based on your setup:"
echo ""
echo "1. If using systemd:"
echo "   sudo systemctl restart gspaces"
echo ""
echo "2. If using supervisor:"
echo "   sudo supervisorctl restart gspaces"
echo ""
echo "3. If running manually:"
echo "   Kill the current process and restart with:"
echo "   python3 main.py"
echo ""

echo "=========================================="
echo "What was fixed:"
echo "=========================================="
echo "1. ✓ Renamed wallet_page() to wallet() to match url_for('wallet')"
echo "2. ✓ Added missing referral_benefits variable to template context"
echo "3. ✓ Redeem coupon section is now fully functional"
echo ""
echo "The redeem coupon section should now be visible at:"
echo "http://your-domain.com/wallet"
echo ""
echo -e "${GREEN}Deployment preparation complete!${NC}"
echo "Please restart your Flask application to apply changes."

# Made with Bob
