#!/bin/bash

# Script to update remaining admin pages with consistent sidebar layout

echo "Updating remaining admin pages with consistent sidebar layout..."

# List of files to update
files=(
    "templates/admin_customers.html"
    "templates/admin_deals.html"
    "templates/admin_gst_settings.html"
    "templates/admin_referral_coupons.html"
    "templates/admin_blogs.html"
    "templates/admin_categories.html"
    "templates/admin_order_detail.html"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        # Backup the file
        cp "$file" "${file}.backup_sidebar_$(date +%Y%m%d_%H%M%S)"
    else
        echo "Warning: $file not found, skipping..."
    fi
done

echo "Backups created. Manual updates required for proper layout consistency."
echo "All admin pages should now use the admin_sidebar.html component."

# Made with Bob
