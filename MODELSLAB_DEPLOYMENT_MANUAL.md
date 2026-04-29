# ModelsLab AI Visualization - Manual Deployment Steps

## Overview
This guide helps you deploy the ModelsLab AI visualization fix to replace the broken Gemini API.

## Prerequisites
- SSH access to your server
- Git repository access
- ModelsLab API key (get from https://modelslab.com/dashboard)

---

## Step 1: Find Your Flask App Location

First, locate where your Flask app is running:

```bash
# Find the main.py location
sudo find / -name "main.py" -path "*/gspaces/*" 2>/dev/null

# OR check common locations:
ls -la ~/gspaces/main.py
ls -la /home/ec2-user/gspaces/main.py
ls -la /opt/gspaces/main.py
ls -la /var/www/gspaces/main.py
```

Let's say your app is at: `/home/ec2-user/gspaces`

---

## Step 2: Backup Current File

```bash
cd /home/ec2-user/gspaces  # Use YOUR actual path

# Create backup
cp ai_visualization_routes.py ai_visualization_routes.py.backup_$(date +%Y%m%d_%H%M%S)
```

---

## Step 3: Pull Latest Changes

```bash
# Pull the ModelsLab fix from GitHub
git pull origin ai-room-visualization

# OR if you need to stash local changes first:
git stash
git pull origin ai-room-visualization
git stash pop
```

---

## Step 4: Get ModelsLab API Key

1. Go to: https://modelslab.com/dashboard
2. Sign up (FREE tier available)
3. Copy your API key

---

## Step 5: Set Environment Variable

### Option A: For systemd service

```bash
# Find your service file
sudo find /etc/systemd/system -name "*gspaces*" -o -name "*flask*"

# Edit the service file (example: gspaces.service)
sudo nano /etc/systemd/system/gspaces.service

# Add this line under [Service] section:
Environment="MODELSLAB_API_KEY=your_actual_api_key_here"

# Save and exit (Ctrl+X, Y, Enter)

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart gspaces
```

### Option B: For manual Flask run

```bash
# Add to your shell profile
echo 'export MODELSLAB_API_KEY="your_actual_api_key_here"' >> ~/.bashrc
source ~/.bashrc

# Restart Flask manually
pkill -f "python.*main.py"
cd /home/ec2-user/gspaces  # Use YOUR path
nohup python3 main.py &
```

### Option C: For screen/tmux session

```bash
# If running in screen/tmux
screen -r  # or tmux attach

# Stop Flask (Ctrl+C)

# Set variable and restart
export MODELSLAB_API_KEY="your_actual_api_key_here"
python3 main.py
```

---

## Step 6: Verify Deployment

### Check if Flask is running:

```bash
# Check process
ps aux | grep "python.*main.py"

# Check logs
tail -f nohup.out  # if using nohup
# OR
sudo journalctl -u gspaces -f  # if using systemd
```

### Test the API:

```bash
# Check if the route is loaded
curl http://localhost:5000/visualize/1

# Should return HTML page, not 404
```

---

## Step 7: Test Visualization Feature

1. Open your website in browser
2. Go to any product page
3. Click "Visualize in Your Room" button
4. Upload a room photo
5. Should see: "🎨 Using ModelsLab for AI image generation with control_image!"
6. No more Gemini 404 errors!

---

## Troubleshooting

### Issue: Still getting Gemini errors

**Solution**: Flask is using cached code
```bash
# Clear Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -delete

# Restart Flask
sudo systemctl restart gspaces
# OR
pkill -f "python.*main.py" && python3 main.py
```

### Issue: ModelsLab API key not found

**Solution**: Check environment variable
```bash
# Verify it's set
echo $MODELSLAB_API_KEY

# If empty, set it again and restart Flask
export MODELSLAB_API_KEY="your_key"
```

### Issue: Import errors

**Solution**: Install required packages
```bash
pip3 install requests pillow
```

---

## Quick Reference Commands

```bash
# Your app location (UPDATE THIS!)
APP_DIR="/home/ec2-user/gspaces"

# Full deployment in one go:
cd $APP_DIR
cp ai_visualization_routes.py ai_visualization_routes.py.backup
git pull origin ai-room-visualization
export MODELSLAB_API_KEY="your_key_here"
sudo systemctl restart gspaces  # OR: pkill -f "python.*main.py" && python3 main.py &
tail -f nohup.out  # Check logs
```

---

## What Changed?

### Before (Gemini - BROKEN):
```python
# Used Gemini API v1beta
model = "gemini-1.5-flash"
# ERROR: 404 NOT_FOUND - model not available
```

### After (ModelsLab - WORKING):
```python
# Uses ModelsLab with control_image
payload = {
    "init_image": room_url,      # Empty room
    "control_image": product_url, # Product reference
    "strength": 0.7
}
# ✅ Applies product to room as reference!
```

---

## Support

If you still have issues:
1. Check Flask logs: `tail -f nohup.out` or `journalctl -u gspaces -f`
2. Verify API key is set: `echo $MODELSLAB_API_KEY`
3. Confirm file updated: `grep -n "modelslab" ai_visualization_routes.py`
4. Test API directly: `curl -X POST http://localhost:5000/api/visualize/generate`

---

**Made with Bob** 🤖