#!/bin/bash

# Deploy Navbar Mobile Visibility Fix
# This script fixes the logo and menu visibility issue on small screen devices

echo "🚀 Deploying Navbar Mobile Visibility Fix..."

# Backup current CSS
echo "📦 Creating backup..."
cp static/css/main.css static/css/main.css.backup_$(date +%Y%m%d_%H%M%S)

# The changes are already in main.css, so we just need to restart the server
echo "✅ CSS changes applied to static/css/main.css"

echo ""
echo "📋 Changes made:"
echo "  ✓ Added semi-transparent dark background for navbar on mobile (index page)"
echo "  ✓ Added backdrop blur effect for better visibility"
echo "  ✓ Styled navbar-toggler (hamburger menu) with white icon for index page"
echo "  ✓ Styled navbar-toggler with dark icon for other pages"
echo ""

echo "🔄 To apply changes on server:"
echo "  1. Upload the updated static/css/main.css file"
echo "  2. Clear browser cache or do a hard refresh (Ctrl+Shift+R)"
echo "  3. Test on mobile device or browser dev tools mobile view"
echo ""

echo "✅ Deployment preparation complete!"
echo ""
echo "💡 What was fixed:"
echo "  - Logo is now visible on mobile devices (white logo on dark background)"
echo "  - Menu items are visible (white text on dark background)"
echo "  - Hamburger menu icon is visible and properly styled"
echo "  - Semi-transparent background allows banner to show through"
echo "  - Backdrop blur creates a modern, professional look"

# Made with Bob
