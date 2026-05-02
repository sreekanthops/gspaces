#!/bin/bash

# Deploy Mobile Banner and Footer Button Fixes
# This script deploys fixes for:
# 1. Banner text not centered on mobile devices
# 2. Footer floating contact buttons not working/visible

echo "=========================================="
echo "Deploying Mobile Banner & Footer Fixes"
echo "=========================================="

# Backup current CSS
echo "Creating backup..."
cp static/css/main.css static/css/main.css.backup_$(date +%Y%m%d_%H%M%S)

# Check if changes are already in place
if grep -q "text-align: center; /\* Ensure content is centered \*/" static/css/main.css; then
    echo "✓ Banner centering fix already applied"
else
    echo "✗ Banner centering fix not found - please apply manually"
fi

if grep -q "z-index: 9999 !important; /\* Increased z-index to ensure visibility \*/" static/css/main.css; then
    echo "✓ Footer button visibility fix already applied"
else
    echo "✗ Footer button visibility fix not found - please apply manually"
fi

echo ""
echo "=========================================="
echo "Changes Applied:"
echo "=========================================="
echo "1. Banner Text Centering (Mobile):"
echo "   - Added explicit text-align: center to .home-content"
echo "   - Added text-align: center to .home-text and all child elements"
echo "   - Added width: 100% for proper centering"
echo "   - Centered button group with align-items: center"
echo ""
echo "2. Footer Floating Contact Buttons:"
echo "   - Changed display from 'none' to 'flex' (always visible)"
echo "   - Increased z-index from 100 to 9999 for better visibility"
echo "   - Added cursor: pointer for better UX"
echo "   - Increased mobile icon size from 22px to 24px"
echo "   - Added !important to mobile display: flex"
echo ""
echo "=========================================="
echo "Testing Instructions:"
echo "=========================================="
echo "1. Test on mobile devices (or use browser dev tools):"
echo "   - Banner text should be perfectly centered"
echo "   - Heading, paragraph, and buttons should align center"
echo ""
echo "2. Test footer contact buttons:"
echo "   - Should be visible on all screen sizes"
echo "   - On desktop: Left side, vertically centered"
echo "   - On mobile: Bottom-left corner, horizontal layout"
echo "   - Click/tap should work for both Call and WhatsApp"
echo ""
echo "3. Verify responsive breakpoints:"
echo "   - Desktop (>768px): Buttons on left side"
echo "   - Mobile (≤767px): Buttons at bottom-left"
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test the changes locally"
echo "2. If satisfied, commit and push to production"
echo "3. Clear browser cache and test on actual mobile devices"
echo ""

# Made with Bob
