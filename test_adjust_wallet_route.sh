#!/bin/bash

echo "🧪 Testing Wallet Adjustment Route"
echo "=================================="

# Check if admin_referral_routes.py exists
if [ -f "admin_referral_routes.py" ]; then
    echo "✅ admin_referral_routes.py exists"
else
    echo "❌ admin_referral_routes.py NOT FOUND"
    exit 1
fi

# Check if the route is defined
if grep -q "adjust-wallet" admin_referral_routes.py; then
    echo "✅ adjust-wallet route found in file"
else
    echo "❌ adjust-wallet route NOT FOUND in file"
    exit 1
fi

# Check if main.py imports and calls the function
if grep -q "from admin_referral_routes import add_admin_referral_routes" main.py; then
    echo "✅ Import statement found in main.py"
else
    echo "❌ Import statement NOT FOUND in main.py"
    exit 1
fi

if grep -q "add_admin_referral_routes(app" main.py; then
    echo "✅ Function call found in main.py"
else
    echo "❌ Function call NOT FOUND in main.py"
    exit 1
fi

echo ""
echo "✅ All checks passed!"
echo ""
echo "Now restart the Flask application:"
echo "  sudo systemctl restart gspaces"
echo ""
echo "Then check the Flask logs for any errors:"
echo "  sudo journalctl -u gspaces -n 50 --no-pager"

# Made with Bob
