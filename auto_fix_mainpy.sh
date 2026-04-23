#!/bin/bash

# Auto-fix script to update main.py with category support
# This script will automatically add the required lines to main.py

echo "=========================================="
echo "Auto-fixing main.py for Category Support"
echo "=========================================="
echo ""

# Backup main.py first
echo "Creating backup..."
cp main.py main.py.backup_$(date +%Y%m%d_%H%M%S)
echo "✓ Backup created"
echo ""

# Check if already updated
if grep -q "from category_helper import inject_categories" main.py; then
    echo "✓ main.py already has category support!"
    echo "Just restart your application:"
    echo "  sudo systemctl restart gspaces"
    exit 0
fi

# Find the line number after Flask app creation
APP_LINE=$(grep -n "app = Flask(__name__)" main.py | head -1 | cut -d: -f1)

if [ -z "$APP_LINE" ]; then
    echo "✗ Could not find 'app = Flask(__name__)' in main.py"
    echo "Please update manually following UPDATE_MAIN_PY_INSTRUCTIONS.md"
    exit 1
fi

echo "Found Flask app at line $APP_LINE"
echo ""

# Add imports at the top (after existing imports)
echo "Adding imports..."
sed -i '/^from flask import/a from category_routes import register_category_routes\nfrom category_helper import inject_categories' main.py

# Add context processor after app creation
INJECT_LINE=$((APP_LINE + 1))
echo "Adding context processor at line $INJECT_LINE..."
sed -i "${INJECT_LINE}i\\
\\
# Make categories available to all templates\\
@app.context_processor\\
def inject_categories_to_templates():\\
    return inject_categories()\\
" main.py

# Add route registration before if __name__
echo "Adding route registration..."
sed -i '/if __name__ ==/i # Register category management routes\nregister_category_routes(app)\n' main.py

echo ""
echo "=========================================="
echo "✓ main.py updated successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart your application:"
echo "   sudo systemctl restart gspaces"
echo ""
echo "2. Check if it's running:"
echo "   sudo systemctl status gspaces"
echo ""
echo "3. Visit your site - categories should now appear!"
echo ""
echo "If something goes wrong, restore backup:"
echo "   cp main.py.backup_* main.py"
echo "=========================================="

# Made with Bob
