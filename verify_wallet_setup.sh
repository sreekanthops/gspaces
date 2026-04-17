#!/bin/bash

# Wallet System Verification Script
# Run this on your server to check wallet setup

echo "=========================================="
echo "Wallet System Verification"
echo "=========================================="
echo ""

DB_NAME="gspaces"
DB_USER="sri"

# 1. Check if wallet tables exist
echo "1. Checking wallet tables..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_name IN ('wallet_transactions', 'referral_coupons', 'coupon_usage')
ORDER BY table_name;
SQL
echo ""

# 2. Check users wallet balance
echo "2. Checking users wallet balances..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    id,
    name,
    email,
    wallet_balance,
    referral_code,
    signup_bonus_credited
FROM users
ORDER BY id
LIMIT 10;
SQL
echo ""

# 3. Check wallet transactions
echo "3. Checking wallet transactions..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    COUNT(*) as total_transactions,
    SUM(CASE WHEN transaction_type = 'bonus' THEN 1 ELSE 0 END) as bonus_transactions,
    SUM(CASE WHEN transaction_type = 'credit' THEN 1 ELSE 0 END) as credit_transactions,
    SUM(CASE WHEN transaction_type = 'debit' THEN 1 ELSE 0 END) as debit_transactions
FROM wallet_transactions;
SQL
echo ""

# 4. Check recent transactions
echo "4. Recent wallet transactions..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    wt.id,
    u.name as user_name,
    wt.transaction_type,
    wt.amount,
    wt.balance_after,
    wt.description,
    wt.created_at
FROM wallet_transactions wt
JOIN users u ON wt.user_id = u.id
ORDER BY wt.created_at DESC
LIMIT 10;
SQL
echo ""

# 5. Check referral coupons
echo "5. Checking referral coupons..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT 
    COUNT(*) as total_coupons,
    SUM(times_used) as total_uses,
    SUM(total_referral_earnings) as total_earnings
FROM referral_coupons;
SQL
echo ""

# 6. Check if wallet columns exist in users table
echo "6. Checking wallet columns in users table..."
psql -U $DB_USER -d $DB_NAME << 'SQL'
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('wallet_balance', 'referral_code', 'signup_bonus_credited', 'wallet_bonus_limit')
ORDER BY column_name;
SQL
echo ""

# 7. Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
psql -U $DB_USER -d $DB_NAME -t << 'SQL'
SELECT 
    'Total Users: ' || COUNT(*) as info FROM users
UNION ALL
SELECT 
    'Users with Balance: ' || COUNT(*) FROM users WHERE wallet_balance > 0
UNION ALL
SELECT 
    'Total Wallet Balance: ₹' || COALESCE(SUM(wallet_balance), 0) FROM users
UNION ALL
SELECT 
    'Total Transactions: ' || COUNT(*) FROM wallet_transactions
UNION ALL
SELECT 
    'Referral Codes: ' || COUNT(*) FROM referral_coupons;
SQL
echo ""
echo "=========================================="

# Made with Bob
