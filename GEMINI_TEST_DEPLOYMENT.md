# Gemini 1.5 Pro Test Deployment Guide

## Overview
This guide helps you deploy the Gemini 1.5 Pro test interface for AI image transformation.

**Important Note**: Gemini 1.5 Pro provides **text analysis** of images, not image generation. It can describe how to transform images but doesn't create new images directly.

---

## Step 1: Get FREE Gemini API Key

1. Go to: https://makersuite.google.com/app/apikey
2. Sign in with Google account
3. Click "Create API Key"
4. Copy your API key

**Cost**: 100% FREE (generous free tier)

---

## Step 2: Install Dependencies

```bash
cd /home/ec2-user/gspaces  # Use your actual path

# Install Gemini SDK
pip3 install -r requirements_gemini.txt

# OR install manually:
pip3 install google-generativeai pillow requests
```

---

## Step 3: Set Environment Variable

### Option A: For systemd service

```bash
# Edit service file
sudo nano /etc/systemd/system/gspaces.service

# Add under [Service] section:
Environment="GEMINI_API_KEY=your_actual_api_key_here"

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart gspaces
```

### Option B: For manual Flask run

```bash
# Add to shell profile
echo 'export GEMINI_API_KEY="your_actual_api_key_here"' >> ~/.bashrc
source ~/.bashrc

# Restart Flask
pkill -f "python.*main.py"
python3 main.py
```

---

## Step 4: Pull Latest Code

```bash
cd /home/ec2-user/gspaces
git pull origin ai-room-visualization
```

---

## Step 5: Test the Interface

1. Open browser: `http://your-server-ip:5000/visualize/test`
2. Upload 2 images:
   - **Image 1**: Reference (furniture/product)
   - **Image 2**: Target (empty room)
3. Write custom prompt:
   ```
   Using the furniture from image 1, place it in the room from image 2 
   with realistic lighting and shadows
   ```
4. Click "Generate AI Transformation"

---

## What to Expect

### Gemini 1.5 Pro Response:
Gemini will provide **text description** like:
```
"To place the desk from image 1 into the room from image 2, 
position it against the left wall near the window. The natural 
light will create soft shadows. Add a desk lamp for evening use..."
```

### Important Understanding:
- ✅ Gemini 1.5 Pro: **Analyzes** images and provides text guidance
- ❌ Gemini 1.5 Pro: Does **NOT** generate new images
- 💡 For actual image generation, you need:
  - Imagen 3 (Google's image model - paid)
  - Stable Diffusion (via Replicate/Hugging Face)
  - DALL-E (OpenAI - paid)

---

## Architecture Options

### Option 1: Gemini + Image Generation Model (Recommended)

```
User uploads images
    ↓
Gemini 1.5 Pro analyzes
    ↓
Generates detailed prompt
    ↓
Send to Stable Diffusion/DALL-E
    ↓
Get generated image
```

**Cost**: FREE (Gemini) + $0.01-0.05 per image (SD)

### Option 2: Direct Image Generation (Current)

```
User uploads images
    ↓
ModelsLab/Replicate directly
    ↓
Get generated image
```

**Cost**: $0.01-0.05 per image

---

## Recommended Solution: Gemini + Replicate

### Why This Combo?
1. ✅ Gemini (FREE): Analyzes images, creates perfect prompt
2. ✅ Replicate (FREE tier): Generates actual image
3. ✅ Best quality: AI-optimized prompts
4. ✅ Cost effective: Both have free tiers

### Implementation:

```python
# Step 1: Analyze with Gemini (FREE)
gemini_prompt = "Describe how to place furniture from image 1 into image 2"
analysis = gemini_model.generate_content([gemini_prompt, img1, img2])

# Step 2: Generate with Replicate (FREE tier)
output = replicate.run(
    "stability-ai/sdxl",
    input={
        "prompt": analysis.text,  # Use Gemini's analysis
        "image": target_room
    }
)
```

---

## Quick Commands Reference

```bash
# Your app location
APP_DIR="/home/ec2-user/gspaces"

# Full deployment:
cd $APP_DIR
pip3 install google-generativeai pillow
export GEMINI_API_KEY="your_key"
git pull origin ai-room-visualization
sudo systemctl restart gspaces

# Test:
curl http://localhost:5000/visualize/test
```

---

## Testing Checklist

- [ ] Gemini API key set
- [ ] Dependencies installed
- [ ] Code pulled from git
- [ ] Flask restarted
- [ ] Can access `/visualize/test`
- [ ] Can upload 2 images
- [ ] Can enter custom prompt
- [ ] Receives Gemini text response

---

## Next Steps

After testing Gemini's text analysis:

1. **If satisfied with text analysis**: Keep as-is for guidance
2. **If need actual images**: Implement Gemini + Replicate combo
3. **If need production**: Add proper image generation model

---

## Troubleshooting

### Error: "GEMINI_API_KEY not set"
```bash
echo $GEMINI_API_KEY  # Should show your key
export GEMINI_API_KEY="your_key"
```

### Error: "Module 'google.generativeai' not found"
```bash
pip3 install google-generativeai
```

### Error: "Invalid API key"
- Get new key from https://makersuite.google.com/app/apikey
- Make sure no extra spaces in key

---

## Cost Comparison

| Service | Analysis | Generation | Total |
|---------|----------|------------|-------|
| **Gemini + Replicate** | FREE | FREE tier | $0 |
| **Gemini + Replicate (paid)** | FREE | $0.01-0.05 | ~$0.02 |
| **ModelsLab only** | N/A | $0.002-0.01 | ~$0.01 |
| **OpenAI DALL-E** | N/A | $0.04 | $0.04 |

---

## Support

Test URL: `http://your-server:5000/visualize/test`

Check logs:
```bash
tail -f nohup.out
# OR
sudo journalctl -u gspaces -f
```

---

**Made with Bob** 🤖