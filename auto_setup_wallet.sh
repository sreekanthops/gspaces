#!/bin/bash

# Automated Wallet System Setup Script
# This script automatically integrates the wallet system into your gspaces app

set -e  # Exit on any error

echo "=========================================="
echo "🚀 Wallet System Auto-Setup"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="gspaces"
DB_USER="sri"
DB_HOST="localhost"
DB_PORT="5432"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"

# Step 1: Backup main.py
echo -e "${YELLOW}Step 1: Backing up main.py...${NC}"
if [ -f "main.py" ]; then
    cp main.py "$BACKUP_DIR/main.py.backup"
    echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/main.py.backup${NC}"
else
    echo -e "${RED}✗ main.py not found!${NC}"
    exit 1
fi

# Step 2: Run database migration
echo ""
echo -e "${YELLOW}Step 2: Running database migration...${NC}"
if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -f add_wallet_system.sql > "$BACKUP_DIR/migration.log" 2>&1; then
    echo -e "${GREEN}✓ Database migration completed${NC}"
    echo "  Log saved to: $BACKUP_DIR/migration.log"
else
    echo -e "${RED}✗ Database migration failed${NC}"
    echo "  Check log: $BACKUP_DIR/migration.log"
    exit 1
fi

# Step 3: Add imports to main.py
echo ""
echo -e "${YELLOW}Step 3: Adding wallet imports to main.py...${NC}"

# Check if imports already exist
if grep -q "from wallet_system import" main.py; then
    echo -e "${BLUE}  Imports already exist, skipping...${NC}"
else
    # Find the line with "from datetime import datetime, timedelta" and add after it
    sed -i.tmp '/from datetime import datetime, timedelta/a\
\
# Wallet system imports\
from wallet_system import WalletSystem\
from wallet_routes import add_wallet_routes, integrate_wallet_with_signup, integrate_wallet_with_order
' main.py
    rm main.py.tmp
    echo -e "${GREEN}✓ Wallet imports added${NC}"
fi

# Step 4: Initialize wallet routes
echo ""
echo -e "${YELLOW}Step 4: Initializing wallet routes...${NC}"

if grep -q "add_wallet_routes(app, connect_to_db)" main.py; then
    echo -e "${BLUE}  Wallet routes already initialized, skipping...${NC}"
else
    # Add after login_manager initialization (around line 114)
    sed -i.tmp '/login_manager.login_view = /a\
\
# Initialize wallet routes\
add_wallet_routes(app, connect_to_db)
' main.py
    rm main.py.tmp
    echo -e "${GREEN}✓ Wallet routes initialized${NC}"
fi

# Step 5: Integrate with signup
echo ""
echo -e "${YELLOW}Step 5: Integrating wallet with signup...${NC}"

if grep -q "integrate_wallet_with_signup" main.py; then
    echo -e "${BLUE}  Signup integration already exists, skipping...${NC}"
else
    # Add after user creation in signup function
    # Find the line with "conn.commit()" in signup and add before it
    awk '/def signup\(\):/{flag=1} flag && /conn\.commit\(\)/ && !done{print "                # Credit signup bonus"; print "                integrate_wallet_with_signup(cursor, conn, user_id, name)"; print ""; done=1} {print}' main.py > main.py.new
    mv main.py.new main.py
    echo -e "${GREEN}✓ Signup integration added${NC}"
fi

# Step 6: Integrate with Google OAuth
echo ""
echo -e "${YELLOW}Step 6: Integrating wallet with Google OAuth...${NC}"

if grep -q "integrate_wallet_with_signup.*google" main.py; then
    echo -e "${BLUE}  Google OAuth integration already exists, skipping...${NC}"
else
    # Add in upsert_user_from_google function
    sed -i.tmp '/user_data = cur\.fetchone()/a\
            # Credit signup bonus for new Google users\
            if user_data:\
                integrate_wallet_with_signup(cur, conn, user_data['"'"'id'"'"'], user_data['"'"'name'"'"'])
' main.py
    rm main.py.tmp 2>/dev/null || true
    echo -e "${GREEN}✓ Google OAuth integration added${NC}"
fi

# Step 7: Integrate with payment success
echo ""
echo -e "${YELLOW}Step 7: Integrating wallet with order processing...${NC}"

if grep -q "integrate_wallet_with_order" main.py; then
    echo -e "${BLUE}  Order integration already exists, skipping...${NC}"
else
    # Add after cart deletion in payment_success
    sed -i.tmp '/cur\.execute.*DELETE FROM cart WHERE user_id/a\
        \
        # Integrate wallet system\
        wallet_amount_used = Decimal(str(data.get('"'"'wallet_amount_used'"'"', 0)))\
        referral_code_used = data.get('"'"'referral_code_used'"'"')\
        \
        integrate_wallet_with_order(\
            conn=conn,\
            user_id=current_user.id,\
            order_id=new_order_id,\
            order_amount=final_total,\
            wallet_amount_used=wallet_amount_used,\
            referral_code_used=referral_code_used\
        )
' main.py
    rm main.py.tmp 2>/dev/null || true
    echo -e "${GREEN}✓ Order integration added${NC}"
fi

# Step 8: Verify changes
echo ""
echo -e "${YELLOW}Step 8: Verifying changes...${NC}"

CHECKS=0
PASSED=0

# Check imports
if grep -q "from wallet_system import WalletSystem" main.py; then
    echo -e "${GREEN}✓ Wallet imports present${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Wallet imports missing${NC}"
fi
((CHECKS++))

# Check route initialization
if grep -q "add_wallet_routes" main.py; then
    echo -e "${GREEN}✓ Wallet routes initialized${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Wallet routes not initialized${NC}"
fi
((CHECKS++))

# Check signup integration
if grep -q "integrate_wallet_with_signup" main.py; then
    echo -e "${GREEN}✓ Signup integration present${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Signup integration missing${NC}"
fi
((CHECKS++))

# Check order integration
if grep -q "integrate_wallet_with_order" main.py; then
    echo -e "${GREEN}✓ Order integration present${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Order integration missing${NC}"
fi
((CHECKS++))

# Step 9: Test database
echo ""
echo -e "${YELLOW}Step 9: Testing database setup...${NC}"

# Check if tables exist
if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -c "SELECT 1 FROM wallet_transactions LIMIT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ wallet_transactions table exists${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ wallet_transactions table missing${NC}"
fi
((CHECKS++))

if psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -c "SELECT 1 FROM referral_coupons LIMIT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ referral_coupons table exists${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ referral_coupons table missing${NC}"
fi
((CHECKS++))

# Step 10: Generate summary
echo ""
echo "=========================================="
echo -e "${BLUE}Setup Summary${NC}"
echo "=========================================="
echo ""
echo "Checks passed: $PASSED/$CHECKS"
echo ""

if [ $PASSED -eq $CHECKS ]; then
    echo -e "${GREEN}✅ All checks passed! Wallet system is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Restart your Flask app:"
    echo "   sudo systemctl restart gspaces"
    echo ""
    echo "2. Test the wallet system:"
    echo "   - Create a new user account"
    echo "   - Check if ₹500 bonus is credited"
    echo "   - Visit /wallet page"
    echo ""
    echo "3. Monitor logs:"
    echo "   tail -f /var/log/gspaces/error.log"
    echo ""
else
    echo -e "${YELLOW}⚠️  Some checks failed. Review the output above.${NC}"
    echo ""
    echo "You can restore the backup if needed:"
    echo "  cp $BACKUP_DIR/main.py.backup main.py"
    echo ""
fi

echo "Backup location: $BACKUP_DIR/"
echo ""

# Step 11: Show database stats
echo -e "${YELLOW}Database Statistics:${NC}"
psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT << EOF
SELECT 
    'Total Users' as metric,
    COUNT(*) as value
FROM users
UNION ALL
SELECT 
    'Users with Referral Codes' as metric,
    COUNT(*) as value
FROM users WHERE referral_code IS NOT NULL
UNION ALL
SELECT 
    'Active Referral Coupons' as metric,
    COUNT(*) as value
FROM referral_coupons WHERE is_active = TRUE
UNION ALL
SELECT 
    'Total Wallet Balance' as metric,
    COALESCE(SUM(wallet_balance), 0) as value
FROM users;
EOF

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=========================================="

# Made with Bob
