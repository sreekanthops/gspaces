#!/bin/bash

# Deploy Lead Status System (Customers | Leads | Reminders)
# This script adds the three-column categorization system to leads

echo "=========================================="
echo "Deploying Lead Status System"
echo "=========================================="

# Database connection details
DB_NAME="gspaces"
DB_USER="sri"

echo ""
echo "Step 1: Adding lead_status and reminder columns to database..."
psql -U $DB_USER -d $DB_NAME -f add_lead_status_columns.sql

if [ $? -eq 0 ]; then
    echo "✓ Database schema updated successfully"
else
    echo "✗ Error updating database schema"
    exit 1
fi

echo ""
echo "Step 2: Restarting application..."
sudo systemctl restart gspaces

if [ $? -eq 0 ]; then
    echo "✓ Application restarted successfully"
else
    echo "✗ Error restarting application"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Lead Status System Deployed Successfully!"
echo "=========================================="
echo ""
echo "Features Added:"
echo "  • Three-column layout: CUSTOMERS | LEADS | REMINDERS"
echo "  • All existing leads are in 'LEADS' column by default"
echo "  • Simple buttons to move leads between columns"
echo "  • Reminder date/time tracking"
echo "  • Visual color coding for each status"
echo ""
echo "Usage:"
echo "  1. View leads organized in three columns"
echo "  2. Click 'Customer' button to mark serious buyers"
echo "  3. Click 'Lead' button to move back to leads"
echo "  4. Click 'Reminder' button to set follow-up date/time"
echo ""
echo "Access: http://your-domain/admin/leads"
echo "=========================================="

# Made with Bob
