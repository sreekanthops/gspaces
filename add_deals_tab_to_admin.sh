#!/bin/bash

# Script to add Deals tab to all admin navigation menus
# This updates all admin templates to include the new Deals tab

echo "Adding Deals tab to admin navigation..."

# List of admin template files to update
files=(
    "templates/admin_orders.html"
    "templates/admin_coupons.html"
    "templates/admin_referral_coupons.html"
    "templates/admin_reviews.html"
    "templates/admin_gst_settings.html"
    "templates/admin_customers.html"
    "templates/admin_blogs.html"
    "templates/admin_categories.html"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Updating $file..."
        
        # Check if Deals tab already exists
        if grep -q "admin_deals" "$file"; then
            echo "  ✓ Deals tab already exists in $file"
        else
            # Add Deals tab before the closing </div> of admin-nav
            # Find the line with Blogs tab and add Deals after it
            if grep -q "📝 Blogs" "$file"; then
                sed -i.bak '/📝 Blogs/a\
            <a href="{{ url_for('"'"'admin_deals'"'"') }}" class="admin-nav-btn">🔥 Deals</a>' "$file"
                echo "  ✓ Added Deals tab to $file"
            else
                # If no Blogs tab, add after Customers or GST Settings
                if grep -q "👤 Customers" "$file"; then
                    sed -i.bak '/👤 Customers/a\
            <a href="{{ url_for('"'"'admin_deals'"'"') }}" class="admin-nav-btn">🔥 Deals</a>' "$file"
                    echo "  ✓ Added Deals tab to $file"
                elif grep -q "💰 GST Settings" "$file"; then
                    sed -i.bak '/💰 GST Settings/a\
            <a href="{{ url_for('"'"'admin_deals'"'"') }}" class="admin-nav-btn">🔥 Deals</a>' "$file"
                    echo "  ✓ Added Deals tab to $file"
                fi
            fi
        fi
    else
        echo "  ✗ File not found: $file"
    fi
done

echo ""
echo "Done! Deals tab added to all admin pages."
echo "Backup files created with .bak extension"

# Made with Bob
