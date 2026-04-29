#!/bin/bash

# Setup AI Visualization Environment Variables
# Run this script to configure the Replicate API token

echo "🔧 Setting up AI Visualization environment..."

# IMPORTANT: Replace YOUR_TOKEN_HERE with your actual Replicate API token
# Get it from: https://replicate.com/account/api-tokens
REPLICATE_TOKEN="YOUR_TOKEN_HERE"

# Check if token is set
if [ "$REPLICATE_TOKEN" = "YOUR_TOKEN_HERE" ]; then
    echo "❌ Please edit this script and replace YOUR_TOKEN_HERE with your actual token"
    echo ""
    echo "Get your token from: https://replicate.com/account/api-tokens"
    exit 1
fi

# Set Replicate API token
export REPLICATE_API_TOKEN=$REPLICATE_TOKEN

# Add to bashrc for persistence
if ! grep -q "REPLICATE_API_TOKEN" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Replicate API for AI Room Visualization" >> ~/.bashrc
    echo "export REPLICATE_API_TOKEN=$REPLICATE_TOKEN" >> ~/.bashrc
    echo "✅ Added to ~/.bashrc"
else
    echo "✅ Already in ~/.bashrc"
fi

# For systemd service
echo ""
echo "📝 To add to systemd service, run:"
echo "sudo nano /etc/systemd/system/gspaces.service"
echo ""
echo "Add this line under [Service]:"
echo "Environment=\"REPLICATE_API_TOKEN=$REPLICATE_TOKEN\""
echo ""
echo "Then reload:"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl restart gspaces"
echo ""
echo "✅ Environment configured!"

# Made with Bob
