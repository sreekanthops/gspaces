#!/bin/bash

# Deployment script for Quotation Feedback Feature
# This script adds customer feedback functionality to quotation pages

echo "=========================================="
echo "Deploying Quotation Feedback Feature"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database credentials
DB_NAME="gspaces"
DB_USER="postgres"

echo ""
echo -e "${YELLOW}Step 1: Creating backup...${NC}"
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
echo "Backing up database..."
pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/gspaces_backup.sql"

# Backup files
echo "Backing up files..."
cp templates/quotation_view_simple.html "$BACKUP_DIR/quotation_view_simple.html.backup" 2>/dev/null || true
cp leads_simple.py "$BACKUP_DIR/leads_simple.py.backup" 2>/dev/null || true

echo -e "${GREEN}✓ Backup created in $BACKUP_DIR${NC}"

echo ""
echo -e "${YELLOW}Step 2: Applying database migration...${NC}"
psql -U $DB_USER -d $DB_NAME -f add_quotation_feedback.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database migration applied successfully${NC}"
else
    echo -e "${RED}✗ Database migration failed${NC}"
    echo "To rollback, restore from: $BACKUP_DIR/gspaces_backup.sql"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Verifying changes...${NC}"

# Verify database columns
echo "Checking if feedback columns exist..."
COLUMN_CHECK=$(psql -U $DB_USER -d $DB_NAME -t -c "
    SELECT COUNT(*) 
    FROM information_schema.columns 
    WHERE table_name = 'leads' 
    AND column_name IN ('customer_rating', 'customer_feedback', 'feedback_submitted_at')
")

if [ "$COLUMN_CHECK" -eq 3 ]; then
    echo -e "${GREEN}✓ All feedback columns created successfully${NC}"
else
    echo -e "${RED}✗ Some columns are missing${NC}"
    exit 1
fi

# Verify template file
if grep -q "feedback-section" templates/quotation_view_simple.html; then
    echo -e "${GREEN}✓ Feedback section added to quotation template${NC}"
else
    echo -e "${RED}✗ Feedback section not found in template${NC}"
    exit 1
fi

# Verify backend route
if grep -q "submit-quotation-feedback" leads_simple.py; then
    echo -e "${GREEN}✓ Feedback API route added to backend${NC}"
else
    echo -e "${RED}✗ Feedback API route not found in backend${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 4: Restarting application...${NC}"
# Uncomment the appropriate command for your setup:
# sudo systemctl restart gspaces
# sudo supervisorctl restart gspaces
# pkill -f "python.*main.py" && nohup python main.py &

echo -e "${YELLOW}Note: Please restart your application manually if needed${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "What was deployed:"
echo "  ✓ Customer feedback section in quotation page"
echo "  ✓ Star rating system (1-5 stars)"
echo "  ✓ Feedback text area for comments/questions"
echo "  ✓ Database columns: customer_rating, customer_feedback, feedback_submitted_at"
echo "  ✓ Backend API endpoint: /api/submit-quotation-feedback"
echo ""
echo "Features:"
echo "  • Customers can rate quotations with 1-5 stars"
echo "  • Customers can provide written feedback or questions"
echo "  • Feedback is stored in the leads table"
echo "  • Beautiful UI with gradient design matching quotation style"
echo "  • Real-time validation and success messages"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "To test:"
echo "  1. Open any quotation page (share link)"
echo "  2. Scroll to the feedback section before footer"
echo "  3. Rate with stars and/or add feedback message"
echo "  4. Click 'Submit Feedback' button"
echo "  5. Check database: SELECT customer_rating, customer_feedback FROM leads WHERE id = <lead_id>;"
echo ""
echo -e "${GREEN}Done!${NC}"

# Made with Bob
