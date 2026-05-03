#!/bin/bash

# Fix admin layout - add proper spacing and rounded corners to all admin pages

echo "Fixing admin page layouts..."

# List of admin pages to update
pages=(
    "templates/admin_inquiries.html"
    "templates/admin_users.html"
    "templates/admin_gst_settings.html"
    "templates/admin_customers.html"
    "templates/admin_referral_coupons.html"
    "templates/admin_orders.html"
    "templates/admin_reviews.html"
    "templates/admin_blogs.html"
    "templates/admin_coupons.html"
    "templates/admin_leads_simple.html"
    "templates/admin_deals.html"
    "templates/admin_customer_detail.html"
)

for page in "${pages[@]}"; do
    if [ -f "$page" ]; then
        echo "Processing $page..."
        
        # Update container-fluid styling to add padding
        sed -i.bak 's/style="margin-top: 76px; padding: 0;"/style="margin-top: 76px; padding: 16px 16px 16px 0;"/' "$page"
        
        # Update sidebar column to add padding
        sed -i.bak 's/<div class="col-md-2" style="padding: 0;">/<div class="col-md-2" style="padding: 16px 0 16px 16px;">/' "$page"
        
        # Update main content area to have rounded corners
        sed -i.bak 's/style="background: #f8f9fa; min-height: calc(100vh - 76px); border-radius: 16px 0 0 0;"/style="background: #f8f9fa; min-height: calc(100vh - 92px); border-radius: 16px; padding: 24px;"/' "$page"
        
        # Remove old p-4 class if exists and update
        sed -i.bak 's/<div class="col-md-10 p-4"/<div class="col-md-10"/' "$page"
        
        echo "✓ Updated $page"
    fi
done

echo "Done! All admin pages updated with proper spacing and rounded corners."

# Made with Bob
