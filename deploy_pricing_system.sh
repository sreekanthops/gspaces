#!/bin/bash

# Deployment script for Individual Item Pricing & Discount System
# Run this on the server to deploy the new pricing features

echo "=========================================="
echo "Deploying Pricing & Discount System"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as correct user
if [ "$USER" != "ec2-user" ]; then
    echo -e "${YELLOW}Warning: This script is designed to run as ec2-user${NC}"
fi

# Navigate to project directory
cd ~/gspaces || { echo -e "${RED}Error: Could not find ~/gspaces directory${NC}"; exit 1; }

echo -e "${YELLOW}Step 1: Creating backup...${NC}"
BACKUP_DIR="backups_pricing_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
echo "Backing up database..."
pg_dump -U sri gspaces > "$BACKUP_DIR/gspaces_backup.sql"

# Backup modified files
echo "Backing up files..."
cp leads_simple.py "$BACKUP_DIR/" 2>/dev/null
cp templates/edit_lead_simple.html "$BACKUP_DIR/" 2>/dev/null
cp templates/quotation_view_simple.html "$BACKUP_DIR/" 2>/dev/null

echo -e "${GREEN}✓ Backup created in $BACKUP_DIR${NC}"
echo ""

echo -e "${YELLOW}Step 2: Applying database migration...${NC}"
if [ -f "add_item_pricing_and_discounts.sql" ]; then
    psql -U sri -d gspaces -f add_item_pricing_and_discounts.sql
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database migration applied successfully${NC}"
    else
        echo -e "${RED}✗ Database migration failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Migration file not found: add_item_pricing_and_discounts.sql${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 3: Verifying database schema...${NC}"
psql -U sri -d gspaces -c "\d lead_designs" | grep -E "(table_price|discount_type|subtotal|final_price)"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ New columns verified in database${NC}"
else
    echo -e "${RED}✗ Could not verify new columns${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Checking Python files...${NC}"
if grep -q "table_price" leads_simple.py; then
    echo -e "${GREEN}✓ leads_simple.py updated${NC}"
else
    echo -e "${RED}✗ leads_simple.py not updated${NC}"
fi

if grep -q "calculateTotal" templates/edit_lead_simple.html; then
    echo -e "${GREEN}✓ edit_lead_simple.html updated${NC}"
else
    echo -e "${RED}✗ edit_lead_simple.html not updated${NC}"
fi

if grep -q "discount_type" templates/quotation_view_simple.html; then
    echo -e "${GREEN}✓ quotation_view_simple.html updated${NC}"
else
    echo -e "${RED}✗ quotation_view_simple.html not updated${NC}"
fi
echo ""

echo -e "${YELLOW}Step 5: Restarting application...${NC}"
sudo systemctl restart python3
sleep 3

# Check if service is running
if sudo systemctl is-active --quiet python3; then
    echo -e "${GREEN}✓ Application restarted successfully${NC}"
else
    echo -e "${RED}✗ Application failed to start${NC}"
    echo "Checking logs..."
    sudo journalctl -u python3 -n 20 --no-pager
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 6: Testing the deployment...${NC}"
echo "Please test the following:"
echo "1. Go to Admin → Leads"
echo "2. Edit a lead and add/edit a design"
echo "3. Enter prices for individual items"
echo "4. Verify subtotal auto-calculates"
echo "5. Apply a discount (percentage or fixed)"
echo "6. Verify final price calculates correctly"
echo "7. View the quotation"
echo "8. Verify discount display (crossed-out price + badge)"
echo ""

echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Backup location: $BACKUP_DIR"
echo "Documentation: PRICING_DISCOUNT_FEATURE.md"
echo ""
echo "If you encounter issues:"
echo "1. Check logs: sudo journalctl -u python3 -f"
echo "2. Restore backup: psql -U sri -d gspaces < $BACKUP_DIR/gspaces_backup.sql"
echo "3. Restart service: sudo systemctl restart python3"
echo ""

# Made with Bob
