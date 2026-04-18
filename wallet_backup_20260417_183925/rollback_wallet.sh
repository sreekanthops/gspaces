#!/bin/bash
# Wallet System Rollback Script
# Run this script to restore database to pre-wallet state

set -e

DB_NAME="gspaces"
DB_USER="sri"
BACKUP_FILE="gspaces_pre_wallet.sql"

echo "=========================================="
echo "Wallet System Rollback"
echo "=========================================="
echo ""
echo "WARNING: This will restore your database to the state before wallet deployment."
read -p "Are you sure you want to rollback? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "Step 1: Dropping wallet-related tables..."
psql -U "$DB_USER" -d "$DB_NAME" << 'SQL'
-- Drop wallet tables
DROP TABLE IF EXISTS wallet_transactions CASCADE;
DROP TABLE IF EXISTS referral_coupons CASCADE;
DROP TABLE IF EXISTS coupon_usage CASCADE;

-- Remove wallet columns from users table
ALTER TABLE users DROP COLUMN IF EXISTS wallet_balance;
ALTER TABLE users DROP COLUMN IF EXISTS wallet_bonus_limit;
ALTER TABLE users DROP COLUMN IF EXISTS referral_code;
ALTER TABLE users DROP COLUMN IF EXISTS referred_by_user_id;
ALTER TABLE users DROP COLUMN IF EXISTS signup_bonus_credited;
ALTER TABLE users DROP COLUMN IF EXISTS first_order_completed;

-- Remove wallet columns from orders table
ALTER TABLE orders DROP COLUMN IF EXISTS wallet_amount_used;
ALTER TABLE orders DROP COLUMN IF EXISTS final_paid_amount;
ALTER TABLE orders DROP COLUMN IF EXISTS cashback_earned;
ALTER TABLE orders DROP COLUMN IF EXISTS cashback_credited;

-- Drop functions and triggers
DROP FUNCTION IF EXISTS generate_referral_code(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS auto_generate_referral_code() CASCADE;
DROP VIEW IF EXISTS wallet_summary CASCADE;

SQL

echo "✓ Wallet tables and columns removed"
echo ""

echo "Step 2: Restoring from backup..."
psql -U "$DB_USER" -d "$DB_NAME" -f "$BACKUP_FILE"
echo "✓ Database restored from backup"
echo ""

echo "=========================================="
echo "Rollback completed successfully!"
echo "=========================================="
