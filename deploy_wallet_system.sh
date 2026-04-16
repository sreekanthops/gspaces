#!/bin/bash

# Wallet System Deployment Script
# This script helps deploy the wallet and referral system

echo "=========================================="
echo "Wallet & Referral System Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database credentials
DB_NAME="gspaces"
DB_USER="sri"
DB_HOST="localhost"
DB_PORT="5432"

echo -e "${YELLOW}Step 1: Checking database connection...${NC}"
if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    echo "Please check your database credentials and try again."
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Running database migration...${NC}"
if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -f add_wallet_system.sql > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database migration completed successfully${NC}"
else
    echo -e "${RED}✗ Database migration failed${NC}"
    echo "Please check the SQL file and try again."
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Verifying tables created...${NC}"
TABLES=("wallet_transactions" "referral_coupons" "coupon_usage")
for table in "${TABLES[@]}"; do
    if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -c "SELECT 1 FROM $table LIMIT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Table '$table' exists${NC}"
    else
        echo -e "${RED}✗ Table '$table' not found${NC}"
    fi
done

echo ""
echo -e "${YELLOW}Step 4: Checking Python dependencies...${NC}"
REQUIRED_PACKAGES=("flask" "psycopg2" "flask_login")
for package in "${REQUIRED_PACKAGES[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        echo -e "${GREEN}✓ $package installed${NC}"
    else
        echo -e "${RED}✗ $package not found${NC}"
        echo "Install with: pip install $package"
    fi
done

echo ""
echo -e "${YELLOW}Step 5: Checking file structure...${NC}"
FILES=("wallet_system.py" "wallet_routes.py" "templates/wallet.html" "WALLET_INTEGRATION_GUIDE.md")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
    else
        echo -e "${RED}✗ $file not found${NC}"
    fi
done

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Steps Completed!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update main.py with the changes from WALLET_INTEGRATION_GUIDE.md"
echo "2. Update templates (cart.html, profile.html, login.html)"
echo "3. Restart your Flask application"
echo "4. Test the wallet system with a new user signup"
echo ""
echo "For detailed instructions, see: WALLET_INTEGRATION_GUIDE.md"
echo ""

# Generate a quick test report
echo -e "${YELLOW}Generating test report...${NC}"
psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT << EOF
-- Test Report
SELECT 
    'Total Users' as metric,
    COUNT(*) as value
FROM users
UNION ALL
SELECT 
    'Users with Wallet Balance' as metric,
    COUNT(*) as value
FROM users WHERE wallet_balance > 0
UNION ALL
SELECT 
    'Total Referral Codes' as metric,
    COUNT(*) as value
FROM referral_coupons
UNION ALL
SELECT 
    'Active Referral Codes' as metric,
    COUNT(*) as value
FROM referral_coupons WHERE is_active = TRUE
UNION ALL
SELECT 
    'Total Wallet Transactions' as metric,
    COUNT(*) as value
FROM wallet_transactions;
EOF

echo ""
echo -e "${GREEN}Deployment script completed!${NC}"

# Made with Bob
