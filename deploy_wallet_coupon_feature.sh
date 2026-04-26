#!/bin/bash

# Wallet Coupon Feature Deployment Script
# This script deploys the wallet coupon redemption feature

set -e  # Exit on any error

echo "=========================================="
echo "Wallet Coupon Feature Deployment"
echo "=========================================="
echo ""

# Configuration
DB_USER="sri"
DB_NAME="gspaces"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
MIGRATION_FILE="add_wallet_coupon_support.sql"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Step 1: Create backup directory
echo "Step 1: Creating backup directory..."
mkdir -p "$BACKUP_DIR"
print_success "Backup directory created: $BACKUP_DIR"
echo ""

# Step 2: Backup database
echo "Step 2: Backing up database..."
pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/gspaces_backup.sql"
if [ $? -eq 0 ]; then
    print_success "Database backed up successfully"
else
    print_error "Database backup failed"
    exit 1
fi
echo ""

# Step 3: Backup modified files
echo "Step 3: Backing up modified files..."
cp templates/wallet.html "$BACKUP_DIR/wallet.html.backup" 2>/dev/null || true
cp templates/admin_coupons.html "$BACKUP_DIR/admin_coupons.html.backup" 2>/dev/null || true
cp wallet_routes.py "$BACKUP_DIR/wallet_routes.py.backup" 2>/dev/null || true
print_success "Files backed up"
echo ""

# Step 4: Check if migration file exists
echo "Step 4: Checking migration file..."
if [ ! -f "$MIGRATION_FILE" ]; then
    print_error "Migration file not found: $MIGRATION_FILE"
    exit 1
fi
print_success "Migration file found"
echo ""

# Step 5: Apply database migration
echo "Step 5: Applying database migration..."
psql -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"
if [ $? -eq 0 ]; then
    print_success "Database migration applied successfully"
else
    print_error "Database migration failed"
    echo ""
    print_warning "Rolling back..."
    psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_DIR/gspaces_backup.sql"
    exit 1
fi
echo ""

# Step 6: Verify migration
echo "Step 6: Verifying migration..."
COUPON_EXISTS=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM coupons WHERE code = 'GSPACES_DESKS_FOLLOW';")
if [ "$COUPON_EXISTS" -gt 0 ]; then
    print_success "Sample coupon created successfully"
else
    print_warning "Sample coupon not found (may need manual creation)"
fi

# Check if columns exist
COLUMNS_EXIST=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'coupons' AND column_name IN ('coupon_type', 'expiry_type', 'user_id');")
if [ "$COLUMNS_EXIST" -eq 3 ]; then
    print_success "All new columns created successfully"
else
    print_error "Some columns are missing"
    exit 1
fi
echo ""

# Step 7: Display coupon details
echo "Step 7: Sample Coupon Details..."
echo "-----------------------------------"
psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT code, discount_value, coupon_type, expiry_type, is_active FROM coupons WHERE code = 'GSPACES_DESKS_FOLLOW';"
echo ""

# Step 8: Restart application (if needed)
echo "Step 8: Application restart..."
print_warning "Please restart your Flask application manually:"
echo "  sudo systemctl restart gspaces"
echo "  OR"
echo "  pkill -f 'python.*main.py' && python main.py &"
echo ""

# Step 9: Summary
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
print_success "Database migration: COMPLETED"
print_success "Backup location: $BACKUP_DIR"
print_success "Sample coupon: GSPACES_DESKS_FOLLOW (₹1000)"
echo ""
echo "Next Steps:"
echo "1. Restart your Flask application"
echo "2. Visit /wallet to test coupon redemption"
echo "3. Visit /admin/coupons to manage coupons"
echo "4. Check WALLET_COUPON_FEATURE_GUIDE.md for details"
echo ""
print_success "Deployment completed successfully!"
echo ""

# Step 10: Testing instructions
echo "=========================================="
echo "Quick Test"
echo "=========================================="
echo "1. Login to your application"
echo "2. Go to /wallet"
echo "3. Enter coupon code: GSPACES_DESKS_FOLLOW"
echo "4. Click 'Redeem'"
echo "5. Check if ₹1000 is added to wallet"
echo ""

# Rollback instructions
echo "=========================================="
echo "Rollback Instructions (if needed)"
echo "=========================================="
echo "If something goes wrong, restore from backup:"
echo "  psql -U $DB_USER -d $DB_NAME < $BACKUP_DIR/gspaces_backup.sql"
echo "  cp $BACKUP_DIR/*.backup <original_location>"
echo ""

# Made with Bob
