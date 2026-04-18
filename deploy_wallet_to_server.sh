#!/bin/bash

# Wallet System Deployment Script with Backup & Rollback
# This script safely deploys the wallet system with automatic backup

set -e  # Exit on any error

# Configuration
DB_NAME="gspaces"
DB_USER="sri"
BACKUP_DIR="wallet_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/gspaces_pre_wallet.sql"
ROLLBACK_SCRIPT="${BACKUP_DIR}/rollback_wallet.sh"

echo "=========================================="
echo "Wallet System Deployment Script"
echo "=========================================="
echo ""

# Step 1: Create backup directory
echo "Step 1: Creating backup directory..."
mkdir -p "$BACKUP_DIR"
echo "✓ Backup directory created: $BACKUP_DIR"
echo ""

# Step 2: Backup current database
echo "Step 2: Backing up current database..."
pg_dump -U "$DB_USER" -d "$DB_NAME" -F p -f "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    echo "✓ Database backup created: $BACKUP_FILE"
    echo "  Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    echo "✗ Backup failed! Aborting deployment."
    exit 1
fi
echo ""

# Step 3: Create rollback script
echo "Step 3: Creating rollback script..."
cat > "$ROLLBACK_SCRIPT" << 'ROLLBACK_EOF'
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
ROLLBACK_EOF

chmod +x "$ROLLBACK_SCRIPT"
echo "✓ Rollback script created: $ROLLBACK_SCRIPT"
echo ""

# Step 4: Check if wallet tables already exist
echo "Step 4: Checking if wallet system is already installed..."
WALLET_EXISTS=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'wallet_transactions');")

if [ "$WALLET_EXISTS" = "t" ]; then
    echo "⚠ Wallet tables already exist!"
    read -p "Do you want to continue anyway? This will skip table creation. (yes/no): " continue_anyway
    if [ "$continue_anyway" != "yes" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
    SKIP_TABLE_CREATION=true
else
    echo "✓ Wallet system not installed yet"
    SKIP_TABLE_CREATION=false
fi
echo ""

# Step 5: Deploy wallet system
echo "Step 5: Deploying wallet system..."

if [ "$SKIP_TABLE_CREATION" = false ]; then
    echo "  - Creating wallet tables and functions..."
    psql -U "$DB_USER" -d "$DB_NAME" -f add_wallet_system.sql
    echo "✓ Wallet system tables created"
else
    echo "  - Skipping table creation (already exists)"
fi
echo ""

# Step 6: Credit signup bonus to existing users (if not already credited)
echo "Step 6: Crediting signup bonus to users..."
psql -U "$DB_USER" -d "$DB_NAME" << 'SQL'
DO $$
DECLARE
    user_record RECORD;
    bonus_count INTEGER := 0;
BEGIN
    FOR user_record IN 
        SELECT id, name, wallet_balance, signup_bonus_credited 
        FROM users 
        WHERE signup_bonus_credited = FALSE OR signup_bonus_credited IS NULL
    LOOP
        -- Update wallet balance
        UPDATE users 
        SET wallet_balance = COALESCE(wallet_balance, 0) + 500.00, 
            signup_bonus_credited = TRUE
        WHERE id = user_record.id;
        
        -- Add transaction record
        INSERT INTO wallet_transactions (
            user_id, 
            transaction_type, 
            amount, 
            balance_after, 
            description, 
            reference_type
        ) VALUES (
            user_record.id,
            'bonus',
            500.00,
            COALESCE(user_record.wallet_balance, 0) + 500.00,
            'Welcome bonus - Thank you for joining GSpaces!',
            'signup'
        );
        
        bonus_count := bonus_count + 1;
        RAISE NOTICE 'Added ₹500 bonus to user: % (ID: %)', user_record.name, user_record.id;
    END LOOP;
    
    RAISE NOTICE 'Total users credited: %', bonus_count;
END $$;
SQL

echo "✓ Signup bonuses credited"
echo ""

# Step 7: Verify deployment
echo "Step 7: Verifying deployment..."
VERIFICATION=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "
SELECT 
    (SELECT COUNT(*) FROM wallet_transactions) as transactions,
    (SELECT COUNT(*) FROM referral_coupons) as referral_codes,
    (SELECT COUNT(*) FROM users WHERE wallet_balance > 0) as users_with_balance;
")

echo "✓ Deployment verification:"
echo "  - Wallet transactions: $(echo $VERIFICATION | cut -d'|' -f1)"
echo "  - Referral codes: $(echo $VERIFICATION | cut -d'|' -f2)"
echo "  - Users with balance: $(echo $VERIFICATION | cut -d'|' -f3)"
echo ""

# Step 8: Create deployment summary
SUMMARY_FILE="${BACKUP_DIR}/deployment_summary.txt"
cat > "$SUMMARY_FILE" << EOF
Wallet System Deployment Summary
=================================
Date: $(date)
Database: $DB_NAME
User: $DB_USER

Backup Location: $BACKUP_FILE
Rollback Script: $ROLLBACK_SCRIPT

Deployment Status: SUCCESS

Verification Results:
- Wallet transactions: $(echo $VERIFICATION | cut -d'|' -f1)
- Referral codes: $(echo $VERIFICATION | cut -d'|' -f2)
- Users with balance: $(echo $VERIFICATION | cut -d'|' -f3)

To rollback this deployment, run:
  cd $BACKUP_DIR && bash rollback_wallet.sh

EOF

echo "=========================================="
echo "✓ Wallet System Deployed Successfully!"
echo "=========================================="
echo ""
echo "Backup & Rollback Information:"
echo "  - Backup directory: $BACKUP_DIR"
echo "  - Database backup: $BACKUP_FILE"
echo "  - Rollback script: $ROLLBACK_SCRIPT"
echo "  - Summary: $SUMMARY_FILE"
echo ""
echo "To rollback this deployment, run:"
echo "  cd $BACKUP_DIR && bash rollback_wallet.sh"
echo ""
echo "Next steps:"
echo "  1. Restart your Flask application"
echo "  2. Test the wallet feature in user profile"
echo "  3. Keep the backup directory safe for rollback if needed"
echo ""

# Made with Bob
