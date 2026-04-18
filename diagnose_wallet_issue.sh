#!/bin/bash

# Wallet Issue Diagnostic Script
# Run this to find out why wallet section is empty

echo "=========================================="
echo "Wallet Issue Diagnostics"
echo "=========================================="
echo ""

DB_NAME="gspaces"
DB_USER="sri"

# Test 1: Check if wallet tables exist
echo "TEST 1: Do wallet tables exist?"
WALLET_TABLES=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('wallet_transactions', 'referral_coupons', 'coupon_usage');")
if [ "$WALLET_TABLES" -eq 3 ]; then
    echo "✅ PASS: All 3 wallet tables exist"
else
    echo "❌ FAIL: Only $WALLET_TABLES wallet tables found (expected 3)"
    echo "   Run: ./deploy_wallet_to_server.sh"
    exit 1
fi
echo ""

# Test 2: Check if users have wallet_balance column
echo "TEST 2: Does users table have wallet columns?"
WALLET_COLUMNS=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('wallet_balance', 'referral_code');")
if [ "$WALLET_COLUMNS" -eq 2 ]; then
    echo "✅ PASS: Users table has wallet columns"
else
    echo "❌ FAIL: Users table missing wallet columns"
    echo "   Run: ./deploy_wallet_to_server.sh"
    exit 1
fi
echo ""

# Test 3: Check if any user has balance
echo "TEST 3: Do users have wallet balance?"
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN wallet_balance > 0 THEN 1 END) as users_with_balance,
    COALESCE(SUM(wallet_balance), 0) as total_balance
FROM users;
SQL

USERS_WITH_BALANCE=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM users WHERE wallet_balance > 0;")
if [ "$USERS_WITH_BALANCE" -gt 0 ]; then
    echo "✅ PASS: $USERS_WITH_BALANCE users have wallet balance"
else
    echo "⚠️  WARNING: No users have wallet balance"
    echo "   This might be why wallet section appears empty"
    echo ""
    echo "   To credit signup bonus, run:"
    echo "   psql -U $DB_USER -d $DB_NAME -f credit_signup_bonus.sql"
fi
echo ""

# Test 4: Check if transactions exist
echo "TEST 4: Are there any wallet transactions?"
TRANSACTION_COUNT=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM wallet_transactions;")
if [ "$TRANSACTION_COUNT" -gt 0 ]; then
    echo "✅ PASS: $TRANSACTION_COUNT transactions found"
    psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    transaction_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM wallet_transactions
GROUP BY transaction_type;
SQL
else
    echo "⚠️  WARNING: No transactions found"
    echo "   Users need transactions to see wallet history"
fi
echo ""

# Test 5: Check if referral codes exist
echo "TEST 5: Do users have referral codes?"
USERS_WITH_CODES=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM users WHERE referral_code IS NOT NULL;")
TOTAL_USERS=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM users;")
if [ "$USERS_WITH_CODES" -eq "$TOTAL_USERS" ]; then
    echo "✅ PASS: All $TOTAL_USERS users have referral codes"
else
    echo "⚠️  WARNING: Only $USERS_WITH_CODES out of $TOTAL_USERS users have referral codes"
fi
echo ""

# Test 6: Check Flask app configuration
echo "TEST 6: Is Flask app using wallet routes?"
if grep -q "from wallet_system import WalletSystem" main.py; then
    echo "✅ PASS: main.py imports WalletSystem"
else
    echo "❌ FAIL: main.py doesn't import WalletSystem"
    echo "   Add to main.py:"
    echo "   from wallet_system import WalletSystem"
    echo "   from wallet_routes import add_wallet_routes"
fi

if grep -q "add_wallet_routes" main.py; then
    echo "✅ PASS: main.py calls add_wallet_routes"
else
    echo "❌ FAIL: main.py doesn't call add_wallet_routes"
    echo "   Add to main.py after app creation:"
    echo "   add_wallet_routes(app, connect_to_db)"
fi
echo ""

# Test 7: Check if profile route passes wallet data
echo "TEST 7: Does profile route pass wallet data?"
if grep -q "wallet_balance" main.py; then
    echo "✅ PASS: main.py references wallet_balance"
else
    echo "❌ FAIL: Profile route doesn't pass wallet data"
    echo "   The profile route needs to fetch and pass wallet data"
fi
echo ""

# Test 8: Sample user data
echo "TEST 8: Sample user wallet data:"
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    id,
    name,
    email,
    wallet_balance,
    referral_code,
    signup_bonus_credited
FROM users
LIMIT 3;
SQL
echo ""

# Final recommendation
echo "=========================================="
echo "DIAGNOSIS COMPLETE"
echo "=========================================="
echo ""

if [ "$USERS_WITH_BALANCE" -eq 0 ]; then
    echo "🔍 ISSUE FOUND: Users have no wallet balance"
    echo ""
    echo "SOLUTION: Credit signup bonus to users"
    echo ""
    echo "Run this command:"
    echo "----------------------------------------"
    cat << 'SQLCMD'
psql -U sri -d gspaces << 'SQL'
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id, name FROM users WHERE signup_bonus_credited = FALSE OR signup_bonus_credited IS NULL LOOP
        UPDATE users SET wallet_balance = 500.00, signup_bonus_credited = TRUE WHERE id = user_record.id;
        INSERT INTO wallet_transactions (user_id, transaction_type, amount, balance_after, description, reference_type)
        VALUES (user_record.id, 'bonus', 500.00, 500.00, 'Welcome bonus - Thank you for joining GSpaces!', 'signup');
        RAISE NOTICE 'Added ₹500 to user: % (ID: %)', user_record.name, user_record.id;
    END LOOP;
END $$;
SQL
SQLCMD
    echo "----------------------------------------"
else
    echo "✅ Database setup looks good!"
    echo ""
    echo "If wallet section still appears empty:"
    echo "1. Hard refresh browser (Ctrl+Shift+R)"
    echo "2. Check browser console for JavaScript errors"
    echo "3. Verify Flask app was restarted after deployment"
    echo "4. Check Flask logs for errors"
fi
echo ""

# Made with Bob
