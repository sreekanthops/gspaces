#!/bin/bash

# Leads/Quotation System Deployment Script
# This script deploys the simplified leads management system to production

set -e  # Exit on any error

echo "=========================================="
echo "Leads System Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/home/ec2-user/gspaces"
BACKUP_DIR="/home/ec2-user/gspaces_backups/leads_$(date +%Y%m%d_%H%M%S)"
DB_NAME="gspaces"
DB_USER="postgres"

echo -e "${BLUE}Step 1: Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp "$APP_DIR/main.py" "$BACKUP_DIR/main.py.backup" 2>/dev/null || true
cp "$APP_DIR/templates/admin_orders.html" "$BACKUP_DIR/admin_orders.html.backup" 2>/dev/null || true
pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/database_backup.sql"
echo -e "${GREEN}✓ Backup created at $BACKUP_DIR${NC}"
echo ""

echo -e "${BLUE}Step 2: Pulling latest code from leads branch...${NC}"
cd "$APP_DIR"
git fetch origin
git checkout leads
git pull origin leads
echo -e "${GREEN}✓ Code updated${NC}"
echo ""

echo -e "${BLUE}Step 3: Creating upload directories...${NC}"
mkdir -p "$APP_DIR/static/img/leads/reference"
mkdir -p "$APP_DIR/static/img/leads/designs"
chmod 755 "$APP_DIR/static/img/leads/reference"
chmod 755 "$APP_DIR/static/img/leads/designs"
chown -R ec2-user:ec2-user "$APP_DIR/static/img/leads"
echo -e "${GREEN}✓ Upload directories created${NC}"
echo ""

echo -e "${BLUE}Step 4: Setting up database...${NC}"
if [ -f "$APP_DIR/create_leads_simple.sql" ]; then
    echo "Running database schema..."
    psql -U $DB_USER -d $DB_NAME -f "$APP_DIR/create_leads_simple.sql"
    echo -e "${GREEN}✓ Database tables created${NC}"
else
    echo -e "${RED}✗ create_leads_simple.sql not found!${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 5: Verifying files...${NC}"
REQUIRED_FILES=(
    "leads_simple.py"
    "templates/admin_leads_simple.html"
    "templates/create_lead_simple.html"
    "templates/edit_lead_simple.html"
    "templates/quotation_view_simple.html"
)

ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$APP_DIR/$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file ${RED}MISSING${NC}"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo -e "${RED}Some required files are missing!${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 6: Checking main.py integration...${NC}"
if grep -q "from leads_simple import register_leads_routes" "$APP_DIR/main.py"; then
    echo -e "${GREEN}✓ Import statement found${NC}"
else
    echo -e "${RED}✗ Import statement missing in main.py${NC}"
    exit 1
fi

if grep -q "register_leads_routes(app, get_db_connection)" "$APP_DIR/main.py"; then
    echo -e "${GREEN}✓ Route registration found${NC}"
else
    echo -e "${RED}✗ Route registration missing in main.py${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 7: Restarting application...${NC}"
sudo systemctl restart gspaces
sleep 3
echo -e "${GREEN}✓ Application restarted${NC}"
echo ""

echo -e "${BLUE}Step 8: Checking application status...${NC}"
if sudo systemctl is-active --quiet gspaces; then
    echo -e "${GREEN}✓ Application is running${NC}"
else
    echo -e "${RED}✗ Application failed to start!${NC}"
    echo "Checking logs..."
    sudo journalctl -u gspaces -n 50 --no-pager
    exit 1
fi
echo ""

echo -e "${BLUE}Step 9: Verifying database tables...${NC}"
TABLES_CHECK=$(psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('leads', 'lead_designs');")
if [ "$TABLES_CHECK" -eq 2 ]; then
    echo -e "${GREEN}✓ Database tables verified${NC}"
else
    echo -e "${RED}✗ Database tables not found!${NC}"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Access admin panel: https://gspaces.in/admin/orders"
echo "2. Click on '💼 Leads' button in navigation"
echo "3. Create your first lead"
echo ""
echo -e "${YELLOW}Features Available:${NC}"
echo "✓ Create leads with customer info"
echo "✓ Upload reference images"
echo "✓ Add multiple design options"
echo "✓ Select items via checkboxes"
echo "✓ Set manual prices"
echo "✓ Share quotations with customers"
echo ""
echo -e "${YELLOW}Backup Location:${NC}"
echo "$BACKUP_DIR"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "sudo journalctl -u gspaces -f"
echo ""
echo -e "${GREEN}Happy Quoting! 🎉${NC}"

# Made with Bob
