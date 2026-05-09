#!/bin/bash

# Deployment script for Visitor Tracking and System Health Monitoring
# This script sets up the complete visitor tracking system

echo "=========================================="
echo "Visitor Tracking System Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo"
    exit 1
fi

# Backup main.py
print_status "Creating backup of main.py..."
cp main.py main.py.backup_visitor_tracking_$(date +%Y%m%d_%H%M%S)

# Install required Python packages
print_status "Installing required Python packages..."
pip3 install user-agents==2.2.0
if [ $? -eq 0 ]; then
    print_status "Python packages installed successfully"
else
    print_error "Failed to install Python packages"
    exit 1
fi

# Create database tables
print_status "Creating database tables..."
sudo -u postgres psql -d gspaces -f create_visitor_tracking_system.sql
if [ $? -eq 0 ]; then
    print_status "Database tables created successfully"
else
    print_error "Failed to create database tables"
    exit 1
fi

# Set proper permissions
print_status "Setting file permissions..."
chmod 644 visitor_tracking_routes.py
chmod 644 templates/admin_visitors.html
chmod 644 templates/admin_system_health.html
chmod 644 templates/admin_nav.html

# Restart the application
print_status "Restarting Flask application..."
sudo systemctl restart gspaces
if [ $? -eq 0 ]; then
    print_status "Application restarted successfully"
else
    print_warning "Failed to restart application automatically. Please restart manually."
fi

# Wait for application to start
sleep 3

# Test the deployment
print_status "Testing visitor tracking endpoints..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/)
if [ "$response" = "200" ]; then
    print_status "Application is responding correctly"
else
    print_warning "Application returned status code: $response"
fi

echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
print_status "Visitor tracking system deployed successfully!"
echo ""
echo "New Features Added:"
echo "  • Visitor tracking with IP, location, device info"
echo "  • Page view tracking with time spent"
echo "  • System health monitoring"
echo "  • Automatic error alerts via email"
echo "  • Admin dashboard for visitors"
echo "  • Admin dashboard for system health"
echo ""
echo "Admin Panel Access:"
echo "  • Visitors: http://your-domain.com/admin/visitors"
echo "  • System Health: http://your-domain.com/admin/system-health"
echo ""
echo "Configuration:"
echo "  • Set ADMIN_EMAIL environment variable for error alerts"
echo "  • Set SMTP credentials for email notifications"
echo ""
print_warning "Important: Configure email settings in environment variables"
echo "  export SMTP_SERVER='smtp.gmail.com'"
echo "  export SMTP_PORT='587'"
echo "  export SMTP_USERNAME='your-email@gmail.com'"
echo "  export SMTP_PASSWORD='your-app-password'"
echo "  export ADMIN_EMAIL='sreekanthchityala@gmail.com'"
echo ""
echo "=========================================="

# Made with Bob
