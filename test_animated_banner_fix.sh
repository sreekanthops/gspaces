#!/bin/bash

echo "🔧 Testing Animated Banner Setup..."

# Check if animated-banner.js exists
if [ -f "static/js/animated-banner.js" ]; then
    echo "✅ animated-banner.js found"
else
    echo "❌ animated-banner.js NOT found"
    exit 1
fi

# Check if test template exists
if [ -f "templates/test_animated_banner.html" ]; then
    echo "✅ test_animated_banner.html found"
else
    echo "❌ test_animated_banner.html NOT found"
    exit 1
fi

# Check database tables
echo ""
echo "📊 Checking database tables..."
psql -U postgres -d gspaces -c "SELECT COUNT(*) as active_items FROM animated_furniture_items WHERE is_active = true;"
psql -U postgres -d gspaces -c "SELECT * FROM animated_banner_settings LIMIT 1;"

echo ""
echo "🎨 Listing active furniture items:"
psql -U postgres -d gspaces -c "SELECT id, name, category, is_active, display_order FROM animated_furniture_items ORDER BY display_order;"

echo ""
echo "✅ Setup check complete!"
echo ""
echo "🌐 Test the banner at: http://localhost:5000/test-animated-banner"
echo ""
echo "If items don't appear:"
echo "1. Check browser console for JavaScript errors"
echo "2. Verify furniture items are active in database"
echo "3. Check that image paths are correct"
echo "4. Ensure animated_banner_settings has is_enabled = true"

# Made with Bob
