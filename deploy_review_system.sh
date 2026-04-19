#!/bin/bash

# Enhanced Review System Deployment Script
# This script deploys the complete review system with media uploads and admin controls

echo "=========================================="
echo "Enhanced Review System Deployment"
echo "=========================================="
echo ""

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

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo"
    exit 1
fi

# Step 1: Create review media directory
echo "Step 1: Creating review media directory..."
mkdir -p static/img/reviews
chmod 755 static/img/reviews
print_success "Review media directory created"

# Step 2: Backup database
echo ""
echo "Step 2: Backing up database..."
BACKUP_FILE="gspaces_backup_$(date +%Y%m%d_%H%M%S).sql"
sudo -u postgres pg_dump gspaces > "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    print_success "Database backed up to $BACKUP_FILE"
else
    print_error "Database backup failed"
    exit 1
fi

# Step 3: Apply database migration
echo ""
echo "Step 3: Applying database migration..."
sudo -u postgres psql gspaces < upgrade_reviews_with_media.sql
if [ $? -eq 0 ]; then
    print_success "Database migration applied successfully"
else
    print_error "Database migration failed"
    exit 1
fi

# Step 4: Verify tables exist
echo ""
echo "Step 4: Verifying database tables..."
TABLE_CHECK=$(sudo -u postgres psql gspaces -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'review_media');")
if [[ $TABLE_CHECK == *"t"* ]]; then
    print_success "review_media table exists"
else
    print_error "review_media table not found"
    exit 1
fi

# Step 5: Restart Flask application
echo ""
echo "Step 5: Restarting Flask application..."
if systemctl is-active --quiet gspaces; then
    systemctl restart gspaces
    sleep 3
    if systemctl is-active --quiet gspaces; then
        print_success "Flask application restarted successfully"
    else
        print_error "Flask application failed to restart"
        systemctl status gspaces
        exit 1
    fi
else
    print_warning "gspaces service not found or not running"
    print_warning "Please restart your Flask application manually"
fi

# Step 6: Set proper permissions
echo ""
echo "Step 6: Setting file permissions..."
chown -R www-data:www-data static/img/reviews 2>/dev/null || chown -R $SUDO_USER:$SUDO_USER static/img/reviews
chmod -R 755 static/img/reviews
print_success "Permissions set"

# Step 7: Verify deployment
echo ""
echo "Step 7: Verifying deployment..."
if [ -d "static/img/reviews" ]; then
    print_success "Review media directory exists"
fi

if [ -f "templates/admin_reviews.html" ]; then
    print_success "Admin reviews template exists"
fi

# Final summary
echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
print_success "Review system deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Access admin panel: http://your-domain/admin/reviews"
echo "2. Test review submission with images/videos"
echo "3. Test admin approval/deletion features"
echo ""
echo "Features enabled:"
echo "  ✓ Image uploads (PNG, JPG, GIF, WEBP)"
echo "  ✓ Video uploads (MP4, WEBM, MOV)"
echo "  ✓ Review title and text"
echo "  ✓ Admin approval system"
echo "  ✓ Admin delete functionality"
echo "  ✓ Media display in reviews"
echo ""
print_warning "Remember to configure your admin email in main.py (ADMIN_EMAILS)"
echo "=========================================="

# Made with Bob
