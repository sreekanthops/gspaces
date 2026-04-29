#!/bin/bash

# Deals Management System Deployment Script
# This script automates the deployment of the deals management system
# Author: Sri (Sreekanth Chityala)

set -e  # Exit on error

echo "=========================================="
echo "Deals Management System Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo: sudo bash deploy_deals_system.sh"
    exit 1
fi

# Step 1: Backup current database
print_info "Step 1: Creating database backup..."
BACKUP_FILE="gspaces_backup_before_deals_$(date +%Y%m%d_%H%M%S).sql"
sudo -u postgres pg_dump gspaces > "$BACKUP_FILE" 2>/dev/null || {
    print_error "Database backup failed"
    exit 1
}
print_success "Database backed up to: $BACKUP_FILE"
echo ""

# Step 2: Run database schema
print_info "Step 2: Creating deals system tables..."
sudo -u postgres psql -d gspaces -f create_deals_system_postgres.sql > /dev/null 2>&1 || {
    print_error "Database schema creation failed"
    print_info "Restoring from backup..."
    sudo -u postgres psql -d gspaces < "$BACKUP_FILE"
    exit 1
}
print_success "Database tables created successfully"
echo ""

# Step 3: Backup main.py
print_info "Step 3: Backing up main.py..."
cp main.py "main.py.backup_$(date +%Y%m%d_%H%M%S)" || {
    print_error "Failed to backup main.py"
    exit 1
}
print_success "main.py backed up"
echo ""

# Step 4: Update main.py with deals routes
print_info "Step 4: Updating main.py..."

# Check if deals_routes import already exists
if grep -q "from deals_routes import" main.py; then
    print_info "Deals routes already imported in main.py"
else
    # Add import after other route imports
    sed -i '/from chatbot_routes import add_chatbot_routes/a from deals_routes import register_deals_routes, calculate_product_discount, get_active_campaign' main.py || {
        print_error "Failed to add import to main.py"
        exit 1
    }
    print_success "Added deals_routes import"
fi

# Check if deals routes are already registered
if grep -q "register_deals_routes(app)" main.py; then
    print_info "Deals routes already registered in main.py"
else
    # Add route registration after other registrations
    sed -i '/add_chatbot_routes(app)/a \n# Register deals routes\nregister_deals_routes(app)' main.py || {
        print_error "Failed to register deals routes in main.py"
        exit 1
    }
    print_success "Registered deals routes"
fi

echo ""

# Step 5: Update templates
print_info "Step 5: Checking templates..."

# Check if deal_banner.html exists
if [ ! -f "templates/deal_banner.html" ]; then
    print_error "templates/deal_banner.html not found!"
    exit 1
fi
print_success "Deal banner template found"

# Check if admin_deals.html exists
if [ ! -f "templates/admin_deals.html" ]; then
    print_error "templates/admin_deals.html not found!"
    exit 1
fi
print_success "Admin deals template found"

echo ""

# Step 6: Verify deals_routes.py
print_info "Step 6: Verifying deals_routes.py..."
if [ ! -f "deals_routes.py" ]; then
    print_error "deals_routes.py not found!"
    exit 1
fi
print_success "deals_routes.py found"
echo ""

# Step 7: Test database connection
print_info "Step 7: Testing database connection..."
sudo -u postgres psql -d gspaces -c "SELECT COUNT(*) FROM deal_campaigns;" > /dev/null 2>&1 || {
    print_error "Database connection test failed"
    exit 1
}
print_success "Database connection successful"
echo ""

# Step 8: Restart application
print_info "Step 8: Restarting GSpaces application..."
systemctl restart gspaces || {
    print_error "Failed to restart gspaces service"
    print_info "Try manually: sudo systemctl restart gspaces"
    exit 1
}
sleep 3
print_success "Application restarted"
echo ""

# Step 9: Check service status
print_info "Step 9: Checking service status..."
if systemctl is-active --quiet gspaces; then
    print_success "GSpaces service is running"
else
    print_error "GSpaces service is not running!"
    print_info "Check logs: sudo journalctl -u gspaces -n 50"
    exit 1
fi
echo ""

# Step 10: Verify database data
print_info "Step 10: Verifying default data..."
CAMPAIGN_COUNT=$(sudo -u postgres psql -d gspaces -t -c "SELECT COUNT(*) FROM deal_campaigns WHERE name='Welcome Offer';" | tr -d ' ')
if [ "$CAMPAIGN_COUNT" -gt 0 ]; then
    print_success "Default campaign created"
else
    print_error "Default campaign not found"
fi

GLOBAL_DISCOUNT=$(sudo -u postgres psql -d gspaces -t -c "SELECT COUNT(*) FROM global_discount;" | tr -d ' ')
if [ "$GLOBAL_DISCOUNT" -gt 0 ]; then
    print_success "Default global discount created"
else
    print_error "Default global discount not found"
fi
echo ""

# Summary
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
print_success "Database schema installed"
print_success "main.py updated with deals routes"
print_success "Templates verified"
print_success "Application restarted"
echo ""

print_info "Next Steps:"
echo "1. Access admin panel: https://yourdomain.com/admin/deals"
echo "2. Create your first campaign or use the default 'Welcome Offer'"
echo "3. Set global or category discounts"
echo "4. Start countdown timer"
echo "5. Verify deal banner appears on frontend"
echo ""

print_info "Important Files:"
echo "- Database backup: $BACKUP_FILE"
echo "- main.py backup: main.py.backup_*"
echo "- Deployment guide: DEALS_SYSTEM_DEPLOYMENT_GUIDE.md"
echo "- Quick start: DEALS_QUICK_START.md"
echo ""

print_info "Troubleshooting:"
echo "- Check logs: sudo journalctl -u gspaces -f"
echo "- Test database: sudo -u postgres psql -d gspaces"
echo "- Rollback: Restore from backup files"
echo ""

print_success "Deployment completed successfully!"
echo "=========================================="

# Made with Bob
