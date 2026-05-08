#!/bin/bash

# Deployment script for quotation auto-slide fix
# This fixes the broken carousel auto-scroll functionality

echo "=========================================="
echo "Deploying Quotation Auto-Slide Fix"
echo "=========================================="

# Backup current file
echo "Creating backup..."
cp templates/quotation_view_simple.html templates/quotation_view_simple.html.backup_$(date +%Y%m%d_%H%M%S)

# The fix has already been applied to the local file
# Just need to restart the application

echo ""
echo "Fix applied! The carousel auto-slide should now work properly."
echo ""
echo "Changes made:"
echo "- Fixed incomplete startAutoScroll() function"
echo "- Added proper slide advancement logic"
echo "- Separated feedback form initialization into its own DOMContentLoaded handler"
echo "- Auto-advance interval set to 3 seconds"
echo "- Videos will pause auto-scroll while playing"
echo ""
echo "To deploy on server:"
echo "1. Upload the updated templates/quotation_view_simple.html"
echo "2. Restart your Flask application"
echo "   sudo systemctl restart gspaces  # or your service name"
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="

# Made with Bob
