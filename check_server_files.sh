#!/bin/bash

# Check if server files are up to date

echo "=========================================="
echo "Server Files Check"
echo "=========================================="
echo ""

# 1. Check if profile.html has wallet tab
echo "1. Checking if profile.html has wallet tab..."
if grep -q 'id="wallet"' templates/profile.html; then
    echo "✅ profile.html has wallet tab"
    
    # Count lines in wallet section
    WALLET_LINES=$(grep -A 100 'id="wallet"' templates/profile.html | wc -l)
    echo "   Wallet section has $WALLET_LINES lines"
    
    if [ "$WALLET_LINES" -lt 50 ]; then
        echo "   ⚠️  WARNING: Wallet section seems incomplete (less than 50 lines)"
        echo "   Expected: ~140 lines of wallet content"
    fi
else
    echo "❌ profile.html does NOT have wallet tab"
    echo "   You need to pull latest code: git pull origin wallet"
    exit 1
fi
echo ""

# 2. Check if main.py fetches wallet data
echo "2. Checking if main.py fetches wallet data..."
if grep -q "wallet_balance" main.py; then
    echo "✅ main.py references wallet_balance"
else
    echo "❌ main.py does NOT fetch wallet data"
    echo "   You need to pull latest code: git pull origin wallet"
    exit 1
fi

if grep -q "WalletSystem" main.py; then
    echo "✅ main.py imports WalletSystem"
else
    echo "❌ main.py does NOT import WalletSystem"
    exit 1
fi
echo ""

# 3. Check Flask process
echo "3. Checking Flask process..."
FLASK_PID=$(pgrep -f "python.*main.py" | head -1)
if [ -n "$FLASK_PID" ]; then
    echo "✅ Flask is running (PID: $FLASK_PID)"
    
    # Check when it was started
    FLASK_START=$(ps -p $FLASK_PID -o lstart=)
    echo "   Started: $FLASK_START"
    
    # Check if it was started after file modification
    FILE_MOD=$(stat -c %y templates/profile.html 2>/dev/null || stat -f "%Sm" templates/profile.html)
    echo "   profile.html modified: $FILE_MOD"
    echo ""
    echo "   ⚠️  If Flask was started BEFORE file modification, restart it:"
    echo "   sudo systemctl restart gspaces"
else
    echo "❌ Flask is NOT running"
    echo "   Start it: sudo systemctl start gspaces"
fi
echo ""

# 4. Show sample of wallet section from template
echo "4. Sample of wallet section in template:"
echo "----------------------------------------"
grep -A 5 'id="wallet"' templates/profile.html | head -10
echo "----------------------------------------"
echo ""

# 5. Check git status
echo "5. Checking git status..."
GIT_STATUS=$(git status --short templates/profile.html main.py 2>/dev/null)
if [ -z "$GIT_STATUS" ]; then
    echo "✅ Files are up to date with git"
else
    echo "⚠️  Files have local changes:"
    echo "$GIT_STATUS"
    echo ""
    echo "   Run: git status"
fi
echo ""

# 6. Final recommendation
echo "=========================================="
echo "RECOMMENDATION"
echo "=========================================="
echo ""

if grep -q 'id="wallet"' templates/profile.html && [ "$WALLET_LINES" -gt 50 ]; then
    echo "✅ Template file looks good"
    echo ""
    echo "If wallet section still appears empty:"
    echo ""
    echo "1. HARD REFRESH browser:"
    echo "   - Chrome/Firefox: Ctrl+Shift+R (Windows/Linux)"
    echo "   - Chrome/Firefox: Cmd+Shift+R (Mac)"
    echo "   - Safari: Cmd+Option+R"
    echo ""
    echo "2. Check browser console for errors:"
    echo "   - Press F12"
    echo "   - Go to Console tab"
    echo "   - Look for any red errors"
    echo ""
    echo "3. Verify Flask restarted after git pull:"
    echo "   sudo systemctl restart gspaces"
    echo ""
    echo "4. Check Flask logs:"
    echo "   sudo journalctl -u gspaces -n 50 --no-pager"
else
    echo "❌ Template file needs updating"
    echo ""
    echo "Run these commands:"
    echo "   git pull origin wallet"
    echo "   sudo systemctl restart gspaces"
fi
echo ""

# Made with Bob
