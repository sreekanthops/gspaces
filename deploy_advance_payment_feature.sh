#!/bin/bash

# ============================================
# Deploy Advance Payment & Delivery Date Feature
# ============================================

echo "🚀 Deploying Advance Payment & Delivery Date Feature..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Database Migration
echo -e "${BLUE}Step 1: Running database migration...${NC}"
psql -U sri -d gspaces -f add_advance_payment_delivery_date.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database migration completed successfully${NC}"
else
    echo -e "${RED}❌ Database migration failed${NC}"
    exit 1
fi

echo ""

# Step 2: Verify database changes
echo -e "${BLUE}Step 2: Verifying database changes...${NC}"
psql -U sri -d gspaces -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'orders' AND column_name IN ('advance_amount', 'pending_amount', 'expected_delivery_date');"

echo ""

# Step 3: Restart application (if using systemd)
echo -e "${BLUE}Step 3: Restarting application...${NC}"
# Uncomment the appropriate command for your setup:
# sudo systemctl restart gspaces
# sudo systemctl restart gunicorn
# pkill -f "python.*main.py" && nohup python main.py &

echo -e "${YELLOW}⚠️  Please restart your application manually if needed${NC}"

echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo ""
echo "📋 Summary of changes:"
echo "  ✓ Added advance_amount column to orders table"
echo "  ✓ Added pending_amount column to orders table"
echo "  ✓ Added expected_delivery_date column to orders table"
echo "  ✓ Updated email template with payment summary"
echo "  ✓ Updated email template footer with new contact details"
echo "  ✓ Added advance payment field to quotation form"
echo "  ✓ Added delivery date picker to quotation form"
echo "  ✓ Updated backend to handle new fields"
echo ""
echo "📧 Email template changes:"
echo "  • Modified 'What's Next?' section to reflect post-discussion status"
echo "  • Added Payment Summary section showing advance and pending amounts"
echo "  • Updated footer: sreekanth.chityala@gspaces.in | +91-7075077384 | gspaces.in"
echo ""
echo "🎯 Next steps:"
echo "  1. Test creating an order from a quotation"
echo "  2. Verify advance amount and pending amount calculations"
echo "  3. Check email template with payment summary"
echo "  4. Test delivery date picker functionality"
echo ""

# Made with Bob