#!/bin/bash

# Fix Referral Coupon Validation Issue
# This script deploys the fix for referral coupons showing as "invalid" in cart

echo "=========================================="
echo "Fixing Referral Coupon Validation"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup current main.py
echo -e "${YELLOW}Creating backup of main.py...${NC}"
cp main.py main.py.backup_$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}✓ Backup created${NC}"

# Deploy to server
echo ""
echo -e "${YELLOW}Deploying to server...${NC}"
echo "Please run these commands on your EC2 server:"
echo ""
echo "1. Backup current main.py:"
echo "   cd /home/ec2-user/gspaces"
echo "   cp main.py main.py.backup_\$(date +%Y%m%d_%H%M%S)"
echo ""
echo "2. Upload the updated main.py to server"
echo ""
echo "3. Restart the application:"
echo "   sudo systemctl restart gspaces"
echo ""
echo "4. Check logs:"
echo "   sudo journalctl -u gspaces -f"
echo ""

echo -e "${GREEN}=========================================="
echo "What was fixed:"
echo "==========================================${NC}"
echo ""
echo "✓ Updated validate_coupon() function to check both:"
echo "  - Regular coupons table"
echo "  - Referral coupons table (referral_coupons)"
echo ""
echo "✓ Added referral coupon validation logic:"
echo "  - Checks if coupon is active"
echo "  - Checks if coupon has expired"
echo "  - Prevents users from using their own referral code"
echo "  - Prevents duplicate usage of same referral code"
echo ""
echo "✓ Updated payment_success() to process referral bonuses:"
echo "  - Awards 5% bonus to referrer's wallet"
echo "  - Applies 5% discount to referred user"
echo "  - Records coupon usage in database"
echo ""
echo -e "${GREEN}=========================================="
echo "How it works now:"
echo "==========================================${NC}"
echo ""
echo "1. User shares referral code (e.g., CHITYA14)"
echo "2. Friend enters code in cart"
echo "3. System checks referral_coupons table"
echo "4. If valid, applies 5% discount"
echo "5. After payment, referrer gets 5% bonus in wallet"
echo ""
echo -e "${YELLOW}Note: The referral coupon must exist in referral_coupons table${NC}"
echo "Check with: psql -U sri -d gspaces -c \"SELECT * FROM referral_coupons WHERE coupon_code = 'CHITYA14';\""
echo ""

# Made with Bob
