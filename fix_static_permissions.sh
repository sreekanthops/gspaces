#!/bin/bash

# Script to fix permissions for the static directory and its contents

# Navigate to the application directory
cd /home/ec2-user/gspaces

# Set correct permissions for the static directory and its contents
echo "Setting permissions for the static directory..."
chmod -R 755 static/

# Verify the permissions
echo "Verifying permissions for the static directory..."
ls -la static/

# Restart the application to apply changes
echo "Restarting the application..."
sudo systemctl restart gspaces

echo "Permissions fixed and application restarted."

# Made with Bob
