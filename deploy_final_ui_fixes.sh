#!/bin/bash

# Deploy Final UI Fixes for Leads System
# Fixes: Office Table label, price visibility, auto-copy all 17 items

echo "🚀 Deploying Final UI Fixes..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Backup
echo -e "${BLUE}📦 Creating backup...${NC}"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp leads_simple.py "$BACKUP_DIR/" 2>/dev/null || true
cp templates/quotation_view_simple.html "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created in $BACKUP_DIR${NC}"

# Git operations
echo -e "${BLUE}📝 Committing changes...${NC}"
git add leads_simple.py templates/quotation_view_simple.html
git commit -m "Fix: Office Table label, price visibility, auto-copy all 17 items

Changes:
- Changed 'Desk' to 'Office Table' with icon in quotation view
- Fixed final price visibility (removed green text on green background)
- Updated auto-copy to include all 17 quantity-based items with prices
- Delete button already exists in edit page (user clarification needed)

All UI improvements complete!"

echo -e "${BLUE}🔄 Pushing to repository...${NC}"
git push origin leads

echo ""
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo ""
echo "📋 Changes Summary:"
echo "  1. ✅ 'Desk' → 'Office Table' with icon (🪑 → 📋)"
echo "  2. ✅ Final price now visible (white text on green background)"
echo "  3. ✅ Auto-copy includes all 17 items with quantities & prices"
echo "  4. ℹ️  Delete button exists in edit page (lines 205-208)"
echo ""
echo "🔧 Server Deployment:"
echo "  ssh ec2-user@your-server"
echo "  cd /var/www/gspaces"
echo "  git pull origin leads"
echo "  sudo systemctl restart gspaces"
echo ""
echo "🧪 Testing Checklist:"
echo "  [ ] View quotation - verify 'Office Table' label with icon"
echo "  [ ] Check final price is visible (white on green)"
echo "  [ ] Add 2nd design - verify all 17 items copied"
echo "  [ ] Confirm delete button visible in edit page"
echo ""

# Made with Bob
