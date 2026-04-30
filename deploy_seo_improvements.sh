#!/bin/bash

# GSpaces SEO Improvements Deployment Script
# This script deploys all SEO improvements to the production server

set -e  # Exit on any error

echo "=========================================="
echo "GSpaces SEO Improvements Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SERVER_USER="your_server_user"
SERVER_HOST="your_server_host"
SERVER_PATH="/path/to/gspaces"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}Step 1: Creating local backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp main.py "$BACKUP_DIR/main.py.backup" 2>/dev/null || echo "main.py not found locally"
cp sitemap.xml "$BACKUP_DIR/sitemap.xml.backup" 2>/dev/null || echo "sitemap.xml not found locally"
echo -e "${GREEN}✓ Local backup created in $BACKUP_DIR${NC}"
echo ""

echo -e "${YELLOW}Step 2: Validating new files...${NC}"
# Check if new template files exist
if [ ! -f "templates/about.html" ]; then
    echo -e "${RED}✗ Error: templates/about.html not found${NC}"
    exit 1
fi
if [ ! -f "templates/contact.html" ]; then
    echo -e "${RED}✗ Error: templates/contact.html not found${NC}"
    exit 1
fi
if [ ! -f "templates/services.html" ]; then
    echo -e "${RED}✗ Error: templates/services.html not found${NC}"
    exit 1
fi
if [ ! -f "sitemap.xml" ]; then
    echo -e "${RED}✗ Error: sitemap.xml not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ All required files validated${NC}"
echo ""

echo -e "${YELLOW}Step 3: Testing Flask routes syntax...${NC}"
python3 -m py_compile main.py
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ main.py syntax is valid${NC}"
else
    echo -e "${RED}✗ Error: main.py has syntax errors${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 4: Deploying to server...${NC}"
echo "This step requires manual configuration of SERVER_USER, SERVER_HOST, and SERVER_PATH"
echo ""
echo "Manual deployment steps:"
echo "1. Upload new template files:"
echo "   scp templates/about.html $SERVER_USER@$SERVER_HOST:$SERVER_PATH/templates/"
echo "   scp templates/contact.html $SERVER_USER@$SERVER_HOST:$SERVER_PATH/templates/"
echo "   scp templates/services.html $SERVER_USER@$SERVER_HOST:$SERVER_PATH/templates/"
echo ""
echo "2. Upload updated main.py:"
echo "   scp main.py $SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
echo ""
echo "3. Upload updated sitemap.xml:"
echo "   scp sitemap.xml $SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
echo ""
echo "4. Restart Flask application:"
echo "   ssh $SERVER_USER@$SERVER_HOST 'cd $SERVER_PATH && sudo systemctl restart gspaces'"
echo ""

echo -e "${YELLOW}Step 5: Post-deployment verification${NC}"
echo "After deployment, verify the following:"
echo ""
echo "1. Test new pages:"
echo "   - https://gspaces.in/about"
echo "   - https://gspaces.in/contact"
echo "   - https://gspaces.in/services"
echo ""
echo "2. Verify sitemap:"
echo "   - https://gspaces.in/sitemap.xml"
echo ""
echo "3. Submit to Google Search Console:"
echo "   - Go to: https://search.google.com/search-console"
echo "   - Select your property (gspaces.in)"
echo "   - Go to Sitemaps section"
echo "   - Submit: https://gspaces.in/sitemap.xml"
echo ""
echo "4. Request indexing for new pages:"
echo "   - In Google Search Console, use URL Inspection tool"
echo "   - Inspect each new URL and click 'Request Indexing'"
echo ""

echo -e "${YELLOW}Step 6: SEO Checklist${NC}"
echo "Complete these tasks after deployment:"
echo ""
echo "□ Update phone number in templates/contact.html (line 52)"
echo "□ Update address in templates/contact.html (line 45)"
echo "□ Update Schema.org contact info in all templates"
echo "□ Submit sitemap to Google Search Console"
echo "□ Request indexing for /about, /contact, /services"
echo "□ Test all forms and links"
echo "□ Run Lighthouse audit on new pages"
echo "□ Monitor Google Search Console for indexing status"
echo ""

echo -e "${GREEN}=========================================="
echo "Deployment preparation complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review the manual deployment commands above"
echo "2. Execute them on your server"
echo "3. Complete the post-deployment verification"
echo "4. Complete the SEO checklist"
echo ""
echo "Backup location: $BACKUP_DIR"

# Made with Bob
