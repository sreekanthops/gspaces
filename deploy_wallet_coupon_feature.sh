#!/bin/bash

# Wallet Coupon Feature Deployment Script
# This script deploys the wallet coupon feature to the server

echo "=========================================="
echo "Wallet Coupon Feature Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Database credentials (update these)
DB_NAME="gspaces"
DB_USER="sri"
DB_HOST="localhost"

echo -e "${YELLOW}Step 1: Backing up database...${NC}"
pg_dump -U $DB_USER -h $DB_HOST $DB_NAME > wallet_coupon_backup_$(date +%Y%m%d_%H%M%S).sql
echo -e "${GREEN}✓ Database backup created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Running database migration...${NC}"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -f add_wallet_coupon_support.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database migration completed successfully${NC}"
else
    echo -e "${RED}✗ Database migration failed${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 3: Verifying database changes...${NC}"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'coupons' 
AND column_name IN ('coupon_type', 'expiry_type', 'user_id');"

echo ""
echo -e "${YELLOW}Step 4: Checking sample coupon...${NC}"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "
SELECT code, coupon_type, discount_value, expiry_type, valid_until 
FROM coupons 
WHERE code = 'GSPACES_DESKS_FOLLOW';"

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Restart your Flask application"
echo "2. Test the admin coupons page"
echo "3. Create a test wallet coupon"
echo "4. Test coupon redemption (when backend is ready)"
echo ""

# Made with Bob
