#!/bin/bash

# ============================================
# Quotation Order Feature Deployment Script
# ============================================
# Deploys the "Create Order from Quotation" feature

echo "🚀 Starting Quotation Order Feature Deployment..."
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Run database migrations
echo -e "\n${BLUE}Step 1: Running database migrations...${NC}"
psql -U postgres -d gspaces -f enhance_order_setup_schema.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database schema updated successfully${NC}"
else
    echo -e "${RED}❌ Database migration failed${NC}"
    exit 1
fi

# Step 2: Restart Flask application
echo -e "\n${BLUE}Step 2: Restarting Flask application...${NC}"
sudo systemctl restart gspaces
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flask application restarted${NC}"
else
    echo -e "${RED}❌ Failed to restart Flask application${NC}"
    exit 1
fi

# Step 3: Check application status
echo -e "\n${BLUE}Step 3: Checking application status...${NC}"
sleep 3
sudo systemctl status gspaces --no-pager | head -n 10

# Step 4: Verify routes are loaded
echo -e "\n${BLUE}Step 4: Verifying routes...${NC}"
echo "Checking if quotation order routes are registered..."
sudo journalctl -u gspaces -n 50 --no-pager | grep -i "quotation order"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "📋 Feature Summary:"
echo "  • Admin 'Create Order' button added to quotation pages"
echo "  • Modal form with customer details pre-filled"
echo "  • Automatic item extraction from quotation designs"
echo "  • Discount percentage and final price adjustment"
echo "  • Professional email notifications with product images"
echo "  • Order tracking linked to quotations"
echo ""
echo "🔗 Test the feature:"
echo "  1. Login as admin"
echo "  2. Open any quotation page"
echo "  3. Look for green 'Create Order' button"
echo "  4. Fill in customer type and adjust pricing"
echo "  5. Submit to create order and send email"
echo ""
echo "📧 Email notifications will be sent to customers with:"
echo "  • Order confirmation details"
echo "  • Product images and itemized list"
echo "  • Pricing breakdown with discounts"
echo "  • Delivery address and contact info"
echo ""
echo -e "${BLUE}Made with Bob 🤖${NC}"

# Made with Bob
