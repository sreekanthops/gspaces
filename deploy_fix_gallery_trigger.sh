#!/bin/bash

# Deploy fix for design_gallery trigger ID conflict
# This fixes the issue where adding a 2nd design causes a duplicate key error

echo "🔧 Deploying design_gallery trigger fix..."

# Database connection details
DB_NAME="gspaces"
DB_USER="postgres"

# Apply the fix
echo "📝 Applying trigger fix..."
sudo -u postgres psql -d $DB_NAME -f fix_design_gallery_trigger_id_conflict.sql

if [ $? -eq 0 ]; then
    echo "✅ Trigger fix applied successfully!"
    echo ""
    echo "📊 Checking for conflicts..."
    sudo -u postgres psql -d $DB_NAME -c "
        SELECT 
            dg.id as gallery_id,
            dg.lead_design_id,
            dg.title,
            CASE 
                WHEN ld.id IS NULL THEN '❌ ORPHANED'
                ELSE '✅ OK'
            END as status
        FROM design_gallery dg
        LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id
        WHERE dg.auto_synced = true
        ORDER BY dg.id DESC
        LIMIT 10;
    "
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "You can now:"
    echo "1. Try adding a 2nd design again"
    echo "2. The custom items copy feature should also work now"
else
    echo "❌ Error applying trigger fix"
    exit 1
fi

# Made with Bob
