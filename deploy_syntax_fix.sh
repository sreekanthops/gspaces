#!/bin/bash
# Deploy syntax fix to server

echo "Deploying syntax fix..."

# Pull latest changes
git pull origin customer

# Restart the service
sudo systemctl restart gspaces

# Check status
sleep 2
sudo systemctl status gspaces --no-pager -l

echo ""
echo "Deployment complete! Check the status above."
echo "If still failing, run: sudo journalctl -u gspaces -n 50"
