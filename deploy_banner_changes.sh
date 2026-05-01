#!/bin/bash

# Script to deploy the latest changes from the banner branch and restart the application

# SSH into the server
ssh -i ~/Downloads/gspacesnew.pem ec2-user@16.171.111.244 << 'EOF'
    # Navigate to the application directory
    cd /home/ec2-user/gspaces

    # Pull the latest changes from the banner branch
    echo "Pulling the latest changes from the banner branch..."
    git fetch origin
    git checkout banner
    git pull origin banner

    # Restart the application
    echo "Restarting the application..."
    sudo systemctl restart gspaces

    echo "Deployment completed successfully."
EOF

# Made with Bob
