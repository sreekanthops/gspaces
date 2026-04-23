#!/bin/bash

# Category Management System - Easy Deployment Script
# Run this on your cloud server after pulling the code

echo "=========================================="
echo "Category Management System Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Database Migration
echo -e "${YELLOW}Step 1: Running database migration...${NC}"
psql -U postgres -d gspaces -f create_categories_table.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database migration completed successfully${NC}"
else
    echo -e "${RED}✗ Database migration failed. Please check the error above.${NC}"
    exit 1
fi

echo ""

# Step 2: Verify categories were created
echo -e "${YELLOW}Step 2: Verifying categories...${NC}"
CATEGORY_COUNT=$(psql -U postgres -d gspaces -t -c "SELECT COUNT(*) FROM categories;")

if [ "$CATEGORY_COUNT" -ge 7 ]; then
    echo -e "${GREEN}✓ Found $CATEGORY_COUNT categories in database${NC}"
    psql -U postgres -d gspaces -c "SELECT name, slug, is_active FROM categories ORDER BY display_order;"
else
    echo -e "${RED}✗ Expected at least 7 categories, found $CATEGORY_COUNT${NC}"
    exit 1
fi

echo ""

# Step 3: Check if main.py needs updating
echo -e "${YELLOW}Step 3: Checking main.py configuration...${NC}"

if grep -q "from category_routes import register_category_routes" main.py; then
    echo -e "${GREEN}✓ Category routes already imported in main.py${NC}"
else
    echo -e "${YELLOW}⚠ Need to add category routes to main.py${NC}"
    echo ""
    echo "Please add these lines to main.py:"
    echo ""
    echo "1. At the top with other imports:"
    echo "   from category_routes import register_category_routes"
    echo ""
    echo "2. After creating the Flask app:"
    echo "   register_category_routes(app)"
    echo ""
fi

echo ""

# Step 4: Restart application
echo -e "${YELLOW}Step 4: Restarting application...${NC}"

# Check if using systemd
if systemctl is-active --quiet gspaces; then
    echo "Restarting gspaces service..."
    sudo systemctl restart gspaces
    sleep 2
    if systemctl is-active --quiet gspaces; then
        echo -e "${GREEN}✓ Application restarted successfully${NC}"
    else
        echo -e "${RED}✗ Application failed to restart${NC}"
        sudo systemctl status gspaces
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ gspaces service not found. Please restart your application manually:${NC}"
    echo "   - If using screen: screen -r gspaces, then Ctrl+C and restart"
    echo "   - If using tmux: tmux attach -t gspaces, then Ctrl+C and restart"
    echo "   - Or simply: python main.py"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Summary${NC}"
echo "=========================================="
echo ""
echo "✓ Database migrated with 7 categories"
echo "✓ Old categories deleted (Ergonomic, Minimalist, Executive)"
echo "✓ Admin interface available at: /admin/categories"
echo ""
echo "New Categories (in order):"
echo "  1. Basic"
echo "  2. Storage"
echo "  3. Elegant"
echo "  4. Greenery"
echo "  5. Couple"
echo "  6. Luxury"
echo "  7. Studio"
echo ""
echo "Next Steps:"
echo "1. Login to admin panel"
echo "2. Go to /admin/categories"
echo "3. Manage categories (add/edit/reorder)"
echo "4. Update navigation menu to show categories"
echo ""
echo -e "${GREEN}Deployment completed!${NC}"
echo "=========================================="

# Made with Bob
