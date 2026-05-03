#!/bin/bash

# Final fix for admin layout - no gaps, rounded corners everywhere

echo "Applying final layout fixes..."

# Fix all admin pages
for file in templates/admin_*.html; do
    if [ -f "$file" ] && [ "$file" != "templates/admin_sidebar.html" ] && [ "$file" != "templates/admin_nav.html" ]; then
        echo "Fixing $file..."
        
        # Set container padding to 0
        sed -i '' 's/style="margin-top: 76px; padding: 16px;"/style="margin-top: 76px; padding: 0;"/' "$file"
        
        # Update main content with proper margin and rounded corners
        sed -i '' 's/style="background: #f8f9fa; min-height: calc(100vh - 108px); padding: 24px; border-radius: 16px;"/style="background: #f8f9fa; min-height: calc(100vh - 76px); padding: 24px; border-radius: 0 16px 16px 16px; margin-left: 16px;"/' "$file"
    fi
done

echo "✓ All pages fixed!"
