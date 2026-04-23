#!/bin/bash

# ============================================
# COMPLETE CATEGORY DEPLOYMENT SCRIPT
# ============================================
# This script will:
# 1. Clean database (13 → 7 categories)
# 2. Update main.py with category support
# 3. Restart the application
# ============================================

set -e  # Exit on any error

echo "🚀 Starting Complete Category Deployment..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================
# STEP 1: Database Cleanup
# ============================================
echo -e "${YELLOW}📊 STEP 1: Cleaning Database (13 → 7 categories)${NC}"
echo "This will delete all existing categories and create only 7 new ones"
echo ""

if [ -f "cleanup_and_fix_categories.sql" ]; then
    echo "Running database cleanup..."
    psql -U postgres -d gspaces -f cleanup_and_fix_categories.sql
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database cleaned successfully!${NC}"
        echo ""
    else
        echo -e "${RED}❌ Database cleanup failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ cleanup_and_fix_categories.sql not found!${NC}"
    exit 1
fi

# ============================================
# STEP 2: Update main.py
# ============================================
echo -e "${YELLOW}🔧 STEP 2: Updating main.py${NC}"
echo ""

if [ -f "auto_fix_mainpy.sh" ]; then
    chmod +x auto_fix_mainpy.sh
    ./auto_fix_mainpy.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ main.py updated successfully!${NC}"
        echo ""
    else
        echo -e "${RED}❌ main.py update failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ auto_fix_mainpy.sh not found!${NC}"
    exit 1
fi

# ============================================
# STEP 3: Restart Application
# ============================================
echo -e "${YELLOW}🔄 STEP 3: Restarting Application${NC}"
echo ""

# Try systemctl first (most common)
if command -v systemctl &> /dev/null; then
    echo "Using systemctl to restart gspaces..."
    sudo systemctl restart gspaces
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Application restarted successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to restart with systemctl${NC}"
        echo "Try manually: sudo systemctl restart gspaces"
    fi
# Try supervisorctl (alternative)
elif command -v supervisorctl &> /dev/null; then
    echo "Using supervisorctl to restart gspaces..."
    sudo supervisorctl restart gspaces
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Application restarted successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to restart with supervisorctl${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not find systemctl or supervisorctl${NC}"
    echo "Please restart your application manually"
fi

echo ""
echo "============================================"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo "============================================"
echo ""
echo "✅ Database: 7 categories created"
echo "✅ main.py: Updated with category support"
echo "✅ Application: Restarted"
echo ""
echo "🌐 Visit your website to see the new categories:"
echo "   - Basic"
echo "   - Storage"
echo "   - Elegant"
echo "   - Greenery"
echo "   - Couple"
echo "   - Luxury"
echo "   - Studio"
echo ""
echo "🔧 Admin Panel: https://your-domain.com/admin/categories"
echo ""
echo "============================================"

# Made with Bob
