#!/bin/bash

# OTP Verification System Deployment Script
# This script deploys the OTP verification system to the server

echo "=========================================="
echo "OTP Verification System Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as correct user
if [ "$USER" != "sri" ]; then
    echo -e "${RED}Error: This script should be run as user 'sri'${NC}"
    exit 1
fi

# Step 1: Create OTP table
echo -e "${YELLOW}Step 1: Creating OTP verification table...${NC}"
psql -U sri -d gspaces -f create_otp_table.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OTP table created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create OTP table${NC}"
    exit 1
fi

# Step 2: Backup main.py
echo -e "\n${YELLOW}Step 2: Backing up main.py...${NC}"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp main.py "$BACKUP_DIR/main.py.backup"
echo -e "${GREEN}✓ Backup created in $BACKUP_DIR${NC}"

# Step 3: Copy template file
echo -e "\n${YELLOW}Step 3: Deploying OTP verification template...${NC}"
if [ -f "templates/verify_otp.html" ]; then
    echo -e "${GREEN}✓ verify_otp.html already in place${NC}"
else
    echo -e "${RED}✗ verify_otp.html not found${NC}"
    exit 1
fi

# Step 4: Test database connection
echo -e "\n${YELLOW}Step 4: Testing database connection...${NC}"
psql -U sri -d gspaces -c "SELECT COUNT(*) FROM otp_verifications;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    exit 1
fi

# Step 5: Run test suite
echo -e "\n${YELLOW}Step 5: Running test suite...${NC}"
python test_otp_system.py
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Some tests failed (check output above)${NC}"
fi

# Step 6: Restart Flask application
echo -e "\n${YELLOW}Step 6: Restarting Flask application...${NC}"
echo -e "${YELLOW}Please restart your Flask application manually:${NC}"
echo "  - If using systemd: sudo systemctl restart gspaces"
echo "  - If using screen: screen -r gspaces, Ctrl+C, then python main.py"
echo "  - If using pm2: pm2 restart gspaces"

echo ""
echo "=========================================="
echo -e "${GREEN}OTP System Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart Flask application"
echo "2. Test signup flow at: http://your-domain/signup"
echo "3. Monitor logs for any errors"
echo ""
echo "Documentation: OTP_VERIFICATION_GUIDE.md"
echo "=========================================="

# Made with Bob
