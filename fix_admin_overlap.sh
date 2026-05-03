#!/bin/bash

# Fix admin page overlapping issues and gaps

echo "Fixing admin page overlapping and gaps..."

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
        
        # Fix container-fluid - remove padding, add margin-top only
        sed -i.bak2 's/style="margin-top: 76px; padding: 16px 16px 16px 0;"/style="margin-top: 76px; padding: 0;"/' "$page"
        
        # Fix sidebar column - remove all padding
        sed -i.bak2 's/<div class="col-md-2" style="padding: 16px 0 16px 16px;">/<div class="col-md-2" style="padding: 0;">/' "$page"
        
        # Fix main content area - add proper padding and margin
        sed -i.bak2 's/style="background: #f8f9fa; min-height: calc(100vh - 92px); border-radius: 16px; padding: 24px;"/style="background: #f8f9fa; min-height: calc(100vh - 76px); border-radius: 16px; padding: 24px; margin: 16px 16px 16px 0;"/' "$page"
        
        # Also handle cases without the full style attribute
        sed -i.bak2 's/style="background: #f8f9fa; min-height: calc(100vh - 76px);"/style="background: #f8f9fa; min-height: calc(100vh - 76px); border-radius: 16px; padding: 24px; margin: 16px 16px 16px 0;"/' "$page"
        
        echo "✓ Updated $page"
    fi
done

# Clean up backup files
rm -f templates/*.bak2

echo "Done! All admin pages fixed for overlapping and gaps."

# Made with Bob
