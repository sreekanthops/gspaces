#!/bin/bash

echo "Applying correct layout fix..."

# Fix all admin pages
for file in templates/admin_*.html; do
    if [ -f "$file" ] && [ "$file" != "templates/admin_sidebar.html" ] && [ "$file" != "templates/admin_nav.html" ]; then
        echo "Fixing $file..."
        
        # Fix main content - remove margin-left, keep proper styling
        sed -i '' 's/style="background: #f8f9fa; min-height: calc(100vh - 76px); padding: 24px; border-radius: 0 16px 16px 16px; margin-left: 16px;"/style="background: #f8f9fa; min-height: calc(100vh - 76px); padding: 24px;"/' "$file"
    fi
done

echo "✓ All pages fixed!"
