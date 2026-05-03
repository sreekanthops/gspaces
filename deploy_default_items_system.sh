#!/bin/bash

# Deployment script for Default Items Management System
# This script sets up the enhanced default items system with CRUD operations

echo "=========================================="
echo "Default Items Management System Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    print_warning "Please run with sudo for system-wide changes"
    echo "Usage: sudo bash deploy_default_items_system.sh"
    exit 1
fi

# Step 1: Backup current database
print_status "Step 1: Creating database backup..."
sudo -u postgres pg_dump gspaces > "gspaces_backup_before_default_items_$(date +%Y%m%d_%H%M%S).sql"
print_status "Database backup created"

# Step 2: Create enhanced default_items table
print_status "Step 2: Creating enhanced default_items table..."
sudo -u postgres psql gspaces < create_enhanced_default_items.sql
if [ $? -eq 0 ]; then
    print_status "Default items table created successfully"
else
    print_error "Failed to create default items table"
    exit 1
fi

# Step 3: Create icons directory
print_status "Step 3: Creating icons directory..."
mkdir -p /var/www/gspaces/static/img/icons
chown www-data:www-data /var/www/gspaces/static/img/icons
chmod 755 /var/www/gspaces/static/img/icons
print_status "Icons directory created"

# Step 4: Copy updated files
print_status "Step 4: Copying updated files..."

# Backup existing files
cp /var/www/gspaces/leads_routes.py /var/www/gspaces/leads_routes.py.backup_$(date +%Y%m%d_%H%M%S)
cp /var/www/gspaces/templates/admin_default_prices.html /var/www/gspaces/templates/admin_default_prices.html.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Copy new files
cp leads_routes.py /var/www/gspaces/
cp templates/admin_default_prices.html /var/www/gspaces/templates/

# Set permissions
chown www-data:www-data /var/www/gspaces/leads_routes.py
chown www-data:www-data /var/www/gspaces/templates/admin_default_prices.html
print_status "Files copied and permissions set"

# Step 5: Restart services
print_status "Step 5: Restarting services..."
systemctl restart gspaces
systemctl restart nginx

if [ $? -eq 0 ]; then
    print_status "Services restarted successfully"
else
    print_error "Failed to restart services"
    exit 1
fi

# Step 6: Verify deployment
print_status "Step 6: Verifying deployment..."
sleep 2

# Check if service is running
if systemctl is-active --quiet gspaces; then
    print_status "GSpaces service is running"
else
    print_error "GSpaces service is not running"
    exit 1
fi

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    print_status "Nginx service is running"
else
    print_error "Nginx service is not running"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "=========================================="
echo ""
echo "New Features Available:"
echo "  ✓ Enhanced default items management page"
echo "  ✓ Add new items with custom icons"
echo "  ✓ Edit existing items and prices"
echo "  ✓ Delete items"
echo "  ✓ Upload custom icon images"
echo "  ✓ Active/Inactive item status"
echo "  ✓ Display order management"
echo ""
echo "Access the admin panel at:"
echo "  https://yourdomain.com/admin/default-prices"
echo ""
echo "Next Steps:"
echo "  1. Login to admin panel"
echo "  2. Navigate to 'Manage Default Items & Prices'"
echo "  3. Add/Edit items as needed"
echo "  4. Items will auto-sync to edit lead page"
echo ""
print_warning "Remember to test the functionality before using in production!"
echo ""

# Made with Bob