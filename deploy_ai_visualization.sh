#!/bin/bash

# AI Room Visualization Deployment Script
# Deploys the AI visualization feature to GSpaces

echo "🎨 Deploying AI Room Visualization System..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as correct user
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ Don't run as root. Run as ec2-user or app user.${NC}"
   exit 1
fi

# Step 1: Check for Replicate API token
echo -e "${YELLOW}Step 1: Checking Replicate API Token...${NC}"
if [ -z "$REPLICATE_API_TOKEN" ]; then
    echo -e "${RED}❌ REPLICATE_API_TOKEN not set!${NC}"
    echo ""
    echo "Please set your Replicate API token:"
    echo "1. Go to https://replicate.com"
    echo "2. Sign up (free)"
    echo "3. Get your API token from Account Settings"
    echo "4. Set it: export REPLICATE_API_TOKEN='your_token_here'"
    echo ""
    echo "Or add to ~/.bashrc:"
    echo "echo 'export REPLICATE_API_TOKEN=\"your_token\"' >> ~/.bashrc"
    echo "source ~/.bashrc"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ API token found${NC}"
fi

# Step 2: Install Python dependencies
echo ""
echo -e "${YELLOW}Step 2: Installing Python dependencies...${NC}"
pip install -r requirements_ai.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

# Step 3: Create upload directory
echo ""
echo -e "${YELLOW}Step 3: Creating upload directory...${NC}"
mkdir -p static/uploads/visualizations
chmod 755 static/uploads/visualizations
echo -e "${GREEN}✅ Upload directory created${NC}"

# Step 4: Create database table
echo ""
echo -e "${YELLOW}Step 4: Creating database table...${NC}"
echo "Enter PostgreSQL password when prompted:"
psql -U postgres -d gspaces -f create_ai_visualization_table.sql
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database table created${NC}"
else
    echo -e "${RED}❌ Failed to create database table${NC}"
    echo "You may need to run this manually:"
    echo "psql -U postgres -d gspaces -f create_ai_visualization_table.sql"
fi

# Step 5: Check if routes are registered in main.py
echo ""
echo -e "${YELLOW}Step 5: Checking main.py integration...${NC}"
if grep -q "from ai_visualization_routes import register_ai_routes" main.py; then
    echo -e "${GREEN}✅ AI routes already imported in main.py${NC}"
else
    echo -e "${YELLOW}⚠️  Need to add AI routes to main.py${NC}"
    echo ""
    echo "Add these lines to main.py:"
    echo ""
    echo "# Import AI visualization routes"
    echo "from ai_visualization_routes import register_ai_routes"
    echo ""
    echo "# Register AI routes (after other route registrations)"
    echo "register_ai_routes(app)"
    echo ""
fi

# Step 6: Test file permissions
echo ""
echo -e "${YELLOW}Step 6: Checking file permissions...${NC}"
if [ -w "static/uploads/visualizations" ]; then
    echo -e "${GREEN}✅ Upload directory is writable${NC}"
else
    echo -e "${RED}❌ Upload directory is not writable${NC}"
    echo "Run: chmod 755 static/uploads/visualizations"
fi

# Step 7: Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Update main.py (if not done):"
echo "   - Add: from ai_visualization_routes import register_ai_routes"
echo "   - Add: register_ai_routes(app)"
echo ""
echo "2. Restart application:"
echo "   sudo systemctl restart gspaces"
echo ""
echo "3. Add 'Visualize' button to product pages:"
echo "   See AI_VISUALIZATION_GUIDE.md for code snippets"
echo ""
echo "4. Test the feature:"
echo "   Visit: https://gspaces.in/visualize/1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Free Tier: 50 images/month"
echo "💰 Cost After: ~$0.05 per image"
echo "📖 Full Guide: AI_VISUALIZATION_GUIDE.md"
echo ""
echo -e "${GREEN}✅ Ready to visualize!${NC}"
echo ""

# Made with Bob
