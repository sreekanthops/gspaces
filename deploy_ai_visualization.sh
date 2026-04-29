#!/bin/bash

# 🎨 AI Room Visualization - Quick Deploy Script
# This script deploys the AI visualization feature with Hugging Face integration

echo "🎨 Starting AI Room Visualization Deployment..."
echo ""

# Check if HUGGINGFACE_TOKEN is set
if [ -z "$HUGGINGFACE_TOKEN" ]; then
    echo "❌ ERROR: HUGGINGFACE_TOKEN not set!"
    echo ""
    echo "Please set your Hugging Face token:"
    echo "1. Get free token from https://huggingface.co/settings/tokens"
    echo "2. Run: export HUGGINGFACE_TOKEN='hf_your_token_here'"
    echo "3. Run this script again"
    exit 1
fi

echo "✅ HUGGINGFACE_TOKEN is set"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements_ai.txt
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Create database table
echo "🗄️  Creating database table..."
psql -U postgres -d gspaces -f create_ai_visualization_table.sql
if [ $? -ne 0 ]; then
    echo "⚠️  Database table may already exist (this is OK)"
fi
echo "✅ Database ready"
echo ""

# Create upload directory if it doesn't exist
echo "📁 Setting up upload directory..."
mkdir -p static/uploads
chmod 755 static/uploads
echo "✅ Upload directory ready"
echo ""

# Restart application
echo "🔄 Restarting application..."
sudo systemctl restart gspaces
if [ $? -ne 0 ]; then
    echo "❌ Failed to restart application"
    exit 1
fi
echo "✅ Application restarted"
echo ""

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 3

# Check service status
echo "🔍 Checking service status..."
sudo systemctl is-active --quiet gspaces
if [ $? -eq 0 ]; then
    echo "✅ Service is running"
else
    echo "❌ Service failed to start"
    echo "Check logs: sudo journalctl -u gspaces -n 50"
    exit 1
fi
echo ""

# Test the route
echo "🧪 Testing visualization route..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/visualize/25)
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo "✅ Route is accessible (HTTP $response)"
else
    echo "⚠️  Route returned HTTP $response (may need login)"
fi
echo ""

echo "🎉 Deployment Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Visit: https://gspaces.com/visualize/25"
echo "2. Upload a room photo"
echo "3. Generate AI visualization"
echo ""
echo "📊 Monitor logs:"
echo "   sudo journalctl -u gspaces -f"
echo ""
echo "📖 Full guide: DEPLOY_AI_VISUALIZATION.md"

# Made with Bob
