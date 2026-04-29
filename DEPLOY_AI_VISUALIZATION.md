# 🎨 AI Room Visualization - Deployment Guide

## Overview
This guide covers deploying the AI-powered room visualization feature using **Hugging Face's FREE API**.

## ✅ What's Included

### Backend
- `ai_visualization_routes.py` - Flask routes for AI processing
- Uses Hugging Face InferenceClient with `stable-diffusion-xl-refiner-1.0`
- Image-to-image transformation (keeps room structure, adds furniture)
- Fallback to product images if API fails

### Frontend
- `templates/visualize_room.html` - Complete UI with drag & drop
- Before/after comparison view
- Previous visualizations gallery
- Mobile responsive design

### Database
- `room_visualizations` table for storing results
- Tracks user_id, product_id, images, timestamps

## 🚀 Deployment Steps

### Step 1: Get FREE Hugging Face Token

1. Go to https://huggingface.co/
2. Sign up for a free account (no credit card required!)
3. Go to Settings → Access Tokens
4. Create a new token with "Read" permissions
5. Copy the token (starts with `hf_...`)

### Step 2: Set Environment Variable on Server

```bash
# SSH into your server
ssh ec2-user@your-server-ip

# Add Hugging Face token to environment
echo 'export HUGGINGFACE_TOKEN="hf_your_token_here"' >> ~/.bashrc
source ~/.bashrc

# Verify it's set
echo $HUGGINGFACE_TOKEN
```

### Step 3: Deploy Code

```bash
cd /home/ec2-user/gspaces

# Pull latest code
git pull origin ai-room-visualization

# Install dependencies
pip install -r requirements_ai.txt

# Create database table
psql -U postgres -d gspaces -f create_ai_visualization_table.sql

# Restart application
sudo systemctl restart gspaces
```

### Step 4: Verify Deployment

```bash
# Check if service is running
sudo systemctl status gspaces

# Check logs for errors
sudo journalctl -u gspaces -n 50 --no-pager

# Test the route
curl http://localhost:5000/visualize/25
```

## 🧪 Testing

### Test with Valid Product IDs
Available product IDs in your database: 7, 10, 17, 21, 23, 24, 25, 26, 27, 31

1. Visit: `https://gspaces.com/visualize/25`
2. Upload a room photo (JPG/PNG, max 5MB)
3. Click "Generate Visualization"
4. Wait 10-30 seconds for AI processing
5. View before/after comparison

### Expected Behavior
- ✅ Upload shows preview immediately
- ✅ "Generating..." spinner appears
- ✅ AI transforms room with furniture
- ✅ Result shows in before/after view
- ✅ Visualization saves to database
- ✅ Appears in "Previous Visualizations" section

## 🎯 How It Works

### AI Processing Flow

1. **User uploads room photo** → Saved to `static/uploads/room_*.jpg`
2. **Backend receives request** → Validates file and product
3. **Hugging Face API call** → Image-to-image transformation
   - Model: `stabilityai/stable-diffusion-xl-refiner-1.0`
   - Strength: 0.6 (moderate transformation)
   - Prompt: "Transform this room to include professional [category] desk setup..."
4. **Result saved** → `static/uploads/result_*.jpg`
5. **Database record** → Links user, product, images
6. **Response to frontend** → Shows before/after comparison

### Prompt Engineering

The system generates prompts like:
```
Transform this room to include a professional Executive desk setup, 
modern furniture, realistic lighting, high quality, photorealistic, detailed
```

Negative prompt prevents:
```
blurry, distorted, low quality, cartoon, painting
```

## 💰 Cost Analysis

### Hugging Face (FREE!)
- ✅ **Cost**: $0.00 per image
- ✅ **Rate Limit**: ~1000 requests/day (free tier)
- ✅ **Quality**: High (Stable Diffusion XL)
- ✅ **Speed**: 10-30 seconds per image
- ✅ **No Credit Card Required**

### Alternative: Replicate (Paid)
- 💵 Cost: ~$0.05 per image
- Requires credit card and $10 minimum
- Slightly faster (5-15 seconds)

## 🔧 Troubleshooting

### Issue: "HUGGINGFACE_TOKEN not set"
**Solution**: 
```bash
export HUGGINGFACE_TOKEN="hf_your_token_here"
sudo systemctl restart gspaces
```

### Issue: "Import huggingface_hub could not be resolved"
**Solution**:
```bash
pip install huggingface_hub==0.20.3
sudo systemctl restart gspaces
```

### Issue: API returns 429 (Rate Limit)
**Solution**: 
- Free tier has ~1000 requests/day
- Wait a few minutes and try again
- Consider upgrading to Hugging Face Pro ($9/month for unlimited)

### Issue: Generated image doesn't look good
**Solution**:
- Adjust `strength` parameter (0.5-0.8 range)
- Modify prompt in `ai_visualization_routes.py` line 154
- Try different base models (see Hugging Face model hub)

### Issue: Slow generation (>60 seconds)
**Solution**:
- Normal for free tier during peak hours
- Consider using Replicate API for faster results
- Add loading message: "This may take up to 60 seconds..."

## 📊 Monitoring

### Check Usage
```bash
# View recent visualizations
psql -U postgres -d gspaces -c "SELECT * FROM room_visualizations ORDER BY created_at DESC LIMIT 10;"

# Count total visualizations
psql -U postgres -d gspaces -c "SELECT COUNT(*) FROM room_visualizations;"

# View by user
psql -U postgres -d gspaces -c "SELECT user_id, COUNT(*) as total FROM room_visualizations GROUP BY user_id;"
```

### Check Logs
```bash
# Real-time logs
sudo journalctl -u gspaces -f

# Search for AI-related logs
sudo journalctl -u gspaces | grep "🎨"
```

## 🎨 Adding "Visualize" Buttons

### Option 1: Product Detail Page
Edit `templates/product_detail.html`:
```html
<a href="/visualize/{{ product.id }}" class="btn btn-primary">
    <i class="bi bi-magic"></i> Visualize in Your Room
</a>
```

### Option 2: Product Cards (Homepage)
Edit `templates/index.html`:
```html
<a href="/visualize/{{ product.id }}" class="btn btn-sm btn-outline-primary">
    <i class="bi bi-magic"></i> Visualize
</a>
```

## 🚀 Marketing Ideas

1. **Homepage Banner**: "New! See Our Desks in YOUR Room - AI Powered"
2. **Email Campaign**: "Visualize Before You Buy"
3. **Social Media**: Share example transformations
4. **Product Pages**: Prominent "Visualize" button
5. **Checkout Flow**: "Not sure? Visualize it first!"

## 📈 Future Enhancements

1. **Multiple Angles**: Generate 3-4 different views
2. **Style Options**: Modern, Traditional, Minimalist presets
3. **Room Templates**: Pre-made room backgrounds
4. **AR Integration**: Mobile AR view (future)
5. **Social Sharing**: Share visualizations on social media
6. **Comparison Tool**: Compare multiple products in same room

## 🔐 Security Notes

- ✅ Login required for all visualization routes
- ✅ File size limited to 5MB
- ✅ Only JPG/PNG allowed
- ✅ Secure filename handling
- ✅ User-specific file naming
- ✅ Database tracks all generations

## 📞 Support

If you encounter issues:
1. Check logs: `sudo journalctl -u gspaces -n 100`
2. Verify token: `echo $HUGGINGFACE_TOKEN`
3. Test API directly: Visit Hugging Face playground
4. Check database: `psql -U postgres -d gspaces`

## ✨ Success Metrics

Track these KPIs:
- Number of visualizations generated
- Conversion rate (visualize → purchase)
- User engagement time
- Social shares of visualizations
- Customer feedback on accuracy

---

**Status**: ✅ Ready to Deploy
**Cost**: 🆓 FREE (Hugging Face)
**Difficulty**: ⭐⭐ Easy
**Impact**: 🚀 High (Unique Feature!)