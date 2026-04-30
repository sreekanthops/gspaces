#!/bin/bash

# Script to check which nginx configuration is currently active
# Run this on your server to find the active nginx config

echo "=========================================="
echo "Nginx Configuration Checker"
echo "=========================================="
echo ""

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "❌ Nginx is not installed or not in PATH"
    exit 1
fi

echo "✓ Nginx is installed"
echo ""

# Show nginx version
echo "Nginx Version:"
nginx -v
echo ""

# Show main nginx config file location
echo "Main Nginx Config File:"
nginx -T 2>&1 | grep "configuration file" | head -1
echo ""

# Show all included config files
echo "Active Configuration Files:"
nginx -T 2>&1 | grep "# configuration file" | sort -u
echo ""

# Show server blocks (sites)
echo "Active Server Blocks (Sites):"
if [ -d "/etc/nginx/sites-enabled" ]; then
    ls -la /etc/nginx/sites-enabled/
elif [ -d "/etc/nginx/conf.d" ]; then
    ls -la /etc/nginx/conf.d/*.conf
else
    echo "Could not find sites-enabled or conf.d directory"
fi
echo ""

# Check for gspaces configuration
echo "Looking for GSpaces configuration:"
nginx -T 2>&1 | grep -i "gspaces" | head -5
echo ""

# Test nginx configuration
echo "Testing Nginx Configuration:"
sudo nginx -t
echo ""

# Show which config file is being used for gspaces.in
echo "Configuration for gspaces.in:"
nginx -T 2>&1 | grep -A 20 "server_name gspaces.in"
echo ""

echo "=========================================="
echo "To update your nginx config:"
echo "1. Find the active config file from above"
echo "2. Edit it: sudo nano /path/to/config/file"
echo "3. Replace with contents from ngnix.conf"
echo "4. Test: sudo nginx -t"
echo "5. Reload: sudo systemctl reload nginx"
echo "=========================================="

# Made with Bob
