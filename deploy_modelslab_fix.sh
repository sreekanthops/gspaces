#!/bin/bash

# Deploy ModelsLab AI Visualization Fix
# This replaces Gemini with ModelsLab API

echo "🚀 Deploying ModelsLab AI Visualization Fix..."
echo "================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're on the server
if [ ! -f "/var/www/gspaces/main.py" ]; then
    echo -e "${RED}❌ Error: Not on server or gspaces not in /var/www/gspaces${NC}"
    echo "Run this script on your server"
    exit 1
fi

# Backup current file
echo -e "${YELLOW}📦 Creating backup...${NC}"
cp /var/www/gspaces/ai_visualization_routes.py /var/www/gspaces/ai_visualization_routes.py.backup_$(date +%Y%m%d_%H%M%S)

# Copy new file
echo -e "${YELLOW}📝 Updating ai_visualization_routes.py...${NC}"
cp ai_visualization_routes.py /var/www/gspaces/

# Set environment variable for ModelsLab API key
echo -e "${YELLOW}🔑 Setting up ModelsLab API key...${NC}"
echo ""
echo "You need to set the MODELSLAB_API_KEY environment variable."
echo "Get your API key from: https://modelslab.com/dashboard"
echo ""
echo "Add this to your Flask app startup or systemd service:"
echo "export MODELSLAB_API_KEY='your_api_key_here'"
echo ""

# Check if systemd service exists
if [ -f "/etc/systemd/system/gspaces.service" ]; then
    echo -e "${YELLOW}📝 To add the API key to systemd service:${NC}"
    echo "1. Edit: sudo nano /etc/systemd/system/gspaces.service"
    echo "2. Add under [Service] section:"
    echo "   Environment=\"MODELSLAB_API_KEY=your_api_key_here\""
    echo "3. Reload: sudo systemctl daemon-reload"
    echo "4. Restart: sudo systemctl restart gspaces"
fi

# Restart Flask app
echo -e "${YELLOW}🔄 Restarting Flask application...${NC}"
if systemctl is-active --quiet gspaces; then
    sudo systemctl restart gspaces
    echo -e "${GREEN}✅ Service restarted${NC}"
elif pgrep -f "python.*main.py" > /dev/null; then
    pkill -f "python.*main.py"
    echo -e "${GREEN}✅ Flask process killed (restart manually)${NC}"
else
    echo -e "${YELLOW}⚠️  No running Flask app found${NC}"
fi

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Get ModelsLab API key from https://modelslab.com"
echo "2. Set MODELSLAB_API_KEY environment variable"
echo "3. Restart your Flask app"
echo "4. Test the visualization feature"
echo ""
echo "🎨 ModelsLab Features:"
echo "   - Uses control_image parameter (product as reference)"
echo "   - Applies product to empty room"
echo "   - Better quality than Gemini"
echo "   - Free tier available"
echo ""

# Made with Bob
