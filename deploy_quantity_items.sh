#!/bin/bash

# Deployment Script for Quantity-Based Items System
# This script deploys the comprehensive 17-item quotation system with quantities

set -e  # Exit on any error

echo "=========================================="
echo "🚀 Deploying Quantity-Based Items System"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
REMOTE_USER="ec2-user"
REMOTE_HOST="13.127.245.37"
REMOTE_DIR="/home/ec2-user/gspaces"
DB_NAME="gspaces"
DB_USER="sri"

echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo "  • Database: Add 68 new columns (17 items × 4 fields)"
echo "  • Backend: Updated leads_simple.py with quantity handling"
echo "  • Admin UI: All 17 items with quantity inputs"
echo "  • Customer View: Quantity badges (×2, ×3, etc.)"
echo "  • JavaScript: Auto-calculation (qty × price)"
echo ""

# Step 1: Backup current database
echo -e "${YELLOW}Step 1: Creating database backup...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && pg_dump -U ${DB_USER} ${DB_NAME} > backup_before_quantity_items_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${GREEN}✓ Database backup created${NC}"
echo ""

# Step 2: Upload files
echo -e "${YELLOW}Step 2: Uploading files to server...${NC}"
scp add_item_quantities.sql ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
scp leads_simple.py ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
scp templates/edit_lead_simple.html ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/templates/
scp templates/quotation_view_simple.html ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/templates/
echo -e "${GREEN}✓ Files uploaded${NC}"
echo ""

# Step 3: Run database migration
echo -e "${YELLOW}Step 3: Running database migration...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces
echo "Executing SQL migration..."
psql -U sri -d gspaces -f add_item_quantities.sql
if [ $? -eq 0 ]; then
    echo "✓ Database migration completed successfully"
else
    echo "✗ Database migration failed"
    exit 1
fi
ENDSSH
echo -e "${GREEN}✓ Database migration completed${NC}"
echo ""

# Step 4: Set correct permissions
echo -e "${YELLOW}Step 4: Setting file permissions...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces
chmod 644 leads_simple.py
chmod 644 templates/edit_lead_simple.html
chmod 644 templates/quotation_view_simple.html
echo "✓ Permissions set"
ENDSSH
echo -e "${GREEN}✓ Permissions configured${NC}"
echo ""

# Step 5: Restart application
echo -e "${YELLOW}Step 5: Restarting application...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
sudo systemctl restart python3
sleep 3
if systemctl is-active --quiet python3; then
    echo "✓ Application restarted successfully"
else
    echo "✗ Application failed to start"
    sudo systemctl status python3
    exit 1
fi
ENDSSH
echo -e "${GREEN}✓ Application restarted${NC}"
echo ""

# Step 6: Verify deployment
echo -e "${YELLOW}Step 6: Verifying deployment...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /home/ec2-user/gspaces

# Check if new columns exist
echo "Checking database schema..."
psql -U sri -d gspaces -c "\d designs" | grep -q "table_quantity"
if [ $? -eq 0 ]; then
    echo "✓ New quantity columns detected"
else
    echo "✗ Quantity columns not found"
    exit 1
fi

# Check if files are in place
if [ -f "leads_simple.py" ] && [ -f "templates/edit_lead_simple.html" ] && [ -f "templates/quotation_view_simple.html" ]; then
    echo "✓ All files in place"
else
    echo "✗ Some files missing"
    exit 1
fi

echo "✓ Deployment verified"
ENDSSH
echo -e "${GREEN}✓ Verification complete${NC}"
echo ""

# Summary
echo -e "${GREEN}=========================================="
echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📊 What's New:${NC}"
echo "  ✓ 17 Items Total (6 original + 11 new)"
echo "  ✓ Quantity fields for all items"
echo "  ✓ Auto-calculation: quantity × price"
echo "  ✓ Quantity badges in customer view (×2, ×3, etc.)"
echo "  ✓ Custom items now support quantities"
echo ""
echo -e "${BLUE}🎯 New Items Added:${NC}"
echo "  • 🌳 Big Plants"
echo "  • 🌱 Mini Plants"
echo "  • 🖼️ Frames"
echo "  • 📚 Wall Racks"
echo "  • 🎯 Desk Mat"
echo "  • 🗑️ Dustbin"
echo "  • 🟫 Floor Mat"
echo "  • ⌨️ Keyboard"
echo "  • 🖱️ Mouse"
echo "  • 🎨 Paint"
echo "  • 🚪 Wardrobes"
echo ""
echo -e "${BLUE}🔗 Access Points:${NC}"
echo "  • Admin: http://13.127.245.37/admin/leads"
echo "  • Create Lead: http://13.127.245.37/leads/create"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "  1. Test creating a new lead with multiple items"
echo "  2. Verify quantity calculations work correctly"
echo "  3. Check customer quotation view shows quantities"
echo "  4. Test custom items with quantities"
echo ""
echo -e "${GREEN}Deployment completed at: $(date)${NC}"

# Made with Bob
