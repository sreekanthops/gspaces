#!/bin/bash

# Deployment script for Quotation Expiry Feature
# This script deploys the countdown timer and expiry watermark system

echo "========================================="
echo "Quotation Expiry Feature Deployment"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Backup database
echo -e "${YELLOW}Step 1: Creating database backup...${NC}"
sudo -u sri pg_dump gspaces > "gspaces_backup_expiry_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${GREEN}✓ Database backup created${NC}"
echo ""

# Run database migration
echo -e "${YELLOW}Step 2: Running database migration...${NC}"
sudo -u sri psql gspaces < add_quotation_expiry.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database migration completed${NC}"
else
    echo -e "${RED}✗ Database migration failed${NC}"
    exit 1
fi
echo ""

# Copy updated files
echo -e "${YELLOW}Step 3: Deploying updated files...${NC}"
cp templates/quotation_view_simple.html /var/www/gspaces/templates/
cp leads_simple.py /var/www/gspaces/
echo -e "${GREEN}✓ Files deployed${NC}"
echo ""

# Set permissions
echo -e "${YELLOW}Step 4: Setting permissions...${NC}"
chown -R www-data:www-data /var/www/gspaces/templates/
chown www-data:www-data /var/www/gspaces/leads_simple.py
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Restart Flask service
echo -e "${YELLOW}Step 5: Restarting Flask service...${NC}"
systemctl restart gspaces
sleep 2

# Check service status
if systemctl is-active --quiet gspaces; then
    echo -e "${GREEN}✓ Flask service restarted successfully${NC}"
else
    echo -e "${RED}✗ Flask service failed to restart${NC}"
    echo "Check logs with: sudo journalctl -u gspaces -n 50"
    exit 1
fi
echo ""

echo "========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "========================================="
echo ""
echo "Features deployed:"
echo "  ✓ Database columns: valid_until, is_expired"
echo "  ✓ Countdown timer in quotation banner"
echo "  ✓ Expired watermark overlay"
echo "  ✓ Admin controls for expiry management"
echo ""
echo "Default behavior:"
echo "  - New quotations valid for 7 days"
echo "  - Timer shows days/hours/minutes remaining"
echo "  - Warning state when < 24 hours left"
echo "  - Expired overlay when time runs out"
echo ""
echo "Admin controls:"
echo "  - Extend validity by 7 days"
echo "  - Mark as expired immediately"
echo "  - Set custom expiry date"
echo ""
echo "Test the feature:"
echo "  1. Open any quotation page"
echo "  2. Check the timer in the hero section"
echo "  3. Admin can manage expiry from quotation page"
echo ""

# Made with Bob
