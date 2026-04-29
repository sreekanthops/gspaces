# Leonardo.ai Setup Guide - AI Room Visualization

## 🎉 Why Leonardo.ai?

- ✅ **FREE Tier Available** - 150 tokens/day (enough for testing!)
- ✅ **High Quality** - Leonardo Vision XL produces photorealistic results
- ✅ **Image-to-Image** - Perfect for room transformations
- ✅ **Fast Processing** - Results in 10-30 seconds
- ✅ **No Credit Card Required** - Start free immediately

## Quick Start (5 Minutes)

### Step 1: Get API Key (2 minutes)
1. Go to [Leonardo.ai](https://leonardo.ai)
2. Sign up for free account
3. Go to [API Access](https://app.leonardo.ai/settings/api)
4. Click "Create API Key"
5. Copy your API key

### Step 2: Set Environment Variable (1 minute)
```bash
export LEONARDO_API_KEY="your-api-key-here"
```

Or add to `.env` file:
```
LEONARDO_API_KEY=your-api-key-here
```

### Step 3: Restart Flask App (1 minute)
```bash
# Stop current app (Ctrl+C)
python main.py
```

### Step 4: Test It! (1 minute)
1. Go to any product page
2. Click "Visualize in Your Room"
3. Upload a room photo
4. Click "Generate Visualization"
5. Wait 10-30 seconds ✨

## How It Works

### The 4-Step Process

#### 1. Get Upload URL
```python
upload_response = requests.post(
    "https://cloud.leonardo.ai/api/rest/v1/init-image",
    json={"extension": "jpg"},
    headers={"authorization": f"Bearer {API_KEY}"}
)
```

#### 2. Upload Image to S3
```python
with open(room_image, "rb") as f:
    requests.put(upload_url, data=f)
```

#### 3. Start Generation
```python
generation = requests.post(
    "https://cloud.leonardo.ai/api/rest/v1/generations",
    json={
        "modelId": "6bef9f1b-29cb-40c7-b9df-cd93b0fab2ec",  # Leonardo Vision XL
        "prompt": "Transform this room...",
        "init_image_id": image_id,
        "init_strength": 0.4,
        "num_images": 1
    }
)
```

#### 4. Poll for Result
```python
while True:
    status = requests.get(f"https://cloud.leonardo.ai/api/rest/v1/generations/{gen_id}")
    if status['status'] == 'COMPLETE':
        image_url = status['generated_images'][0]['url']
        break
    time.sleep(3)
```

## Free Tier Details

### What You Get FREE
- **150 tokens per day**
- **Resets daily**
- **No credit card required**
- **Full API access**

### Token Usage
- **Image-to-Image:** ~8-10 tokens per generation
- **Daily capacity:** ~15-18 visualizations
- **Perfect for testing and small businesses**

### Cost After Free Tier
If you need more:
- **Apprentice:** $10/month = 8,500 tokens
- **Artisan:** $24/month = 25,000 tokens
- **Maestro:** $48/month = 60,000 tokens

## Configuration Options

### init_strength Parameter
Controls how much the image changes:

```python
"init_strength": 0.3  # Minimal change, mostly original room
"init_strength": 0.4  # Balanced (RECOMMENDED)
"init_strength": 0.5  # More transformation
"init_strength": 0.6  # Strong transformation
```

### Model Options

#### Leonardo Vision XL (Recommended)
```python
"modelId": "6bef9f1b-29cb-40c7-b9df-cd93b0fab2ec"
```
- Best for photorealistic interiors
- Great lighting and shadows
- Natural furniture integration

#### Leonardo Diffusion XL
```python
"modelId": "1e60896f-3c26-4296-8ecc-53e2afecc132"
```
- More artistic style
- Good for creative designs

## Prompt Engineering

### Good Prompts
```python
# Specific and detailed
"Transform this room into a professional home office setup with a modern storage desk, 
cinematic lighting, photorealistic, high quality interior design, realistic shadows 
and reflections, naturally integrated furniture"

# Product-focused
"A sleek ergonomic office chair in this workspace, professional interior design, 
realistic lighting and shadows, seamlessly integrated into the room's aesthetic"
```

### Bad Prompts
```python
# Too vague
"Add a desk"

# Too complex
"Transform this into a futuristic cyberpunk office with neon lights and holographic 
displays and floating furniture and..."
```

## Troubleshooting

### Error: "401 Unauthorized"
**Cause:** Invalid API key
**Solution:**
```bash
# Check your API key
echo $LEONARDO_API_KEY

# Make sure it starts with your actual key
# Re-export if needed
export LEONARDO_API_KEY="your-correct-key"
```

### Error: "Insufficient tokens"
**Cause:** Used up daily free tokens
**Solution:**
- Wait for daily reset (midnight UTC)
- Or upgrade to paid plan
- Or implement rate limiting

### Generation Takes Too Long
**Cause:** Server busy or complex prompt
**Solution:**
- Simplify prompt
- Reduce image size
- Try during off-peak hours

### Poor Quality Results
**Cause:** Wrong init_strength or bad prompt
**Solution:**
```python
# Try different strengths
"init_strength": 0.3  # If too different from original
"init_strength": 0.5  # If not enough change

# Improve prompt
Add: "photorealistic, high quality, detailed, professional"
```

## Best Practices

### 1. Optimize Image Size
```python
# Resize before upload (saves tokens)
max_size = 1024
if image.width > max_size:
    image = image.resize((1024, 768))
```

### 2. Cache Results
```python
# Don't regenerate same visualization
cache_key = f"{user_id}_{product_id}_{room_hash}"
if cached := get_from_cache(cache_key):
    return cached
```

### 3. Rate Limiting
```python
# Limit per user
@limiter.limit("5 per hour")
def generate_visualization():
    # ...
```

### 4. Error Handling
```python
try:
    result = generate_with_leonardo()
except Exception as e:
    # Fallback to simple composite
    result = simple_overlay(room, product)
```

## Production Tips

### 1. Monitor Token Usage
```python
# Track daily usage
daily_count = redis.incr(f"leonardo_usage:{today}")
if daily_count > 150:
    return "Daily limit reached"
```

### 2. Implement Queue System
```python
# For high traffic
from celery import Celery

@celery.task
def generate_async(user_id, product_id, room_path):
    # Generate in background
    # Notify user when complete
```

### 3. Provide Alternatives
```python
if tokens_exhausted:
    return {
        "message": "Free tier limit reached",
        "options": [
            "Try again tomorrow",
            "Upgrade to premium",
            "Use simple preview (free)"
        ]
    }
```

## Example Integration

### Complete Flow
```python
# 1. User uploads room photo
room_image = request.files['room_image']

# 2. Check if user has tokens left
if not has_tokens(user_id):
    return "Daily limit reached"

# 3. Generate visualization
result = leonardo_generate(room_image, product)

# 4. Save and return
save_visualization(user_id, product_id, result)
return jsonify({"image_url": result})
```

### With Fallback
```python
try:
    # Try Leonardo first
    result = leonardo_generate(room, product)
except InsufficientTokens:
    # Fallback to simple composite
    result = simple_composite(room, product)
except Exception as e:
    # Show error
    return error_response(str(e))
```

## Cost Comparison

### Leonardo.ai
- **Free:** 150 tokens/day = ~15 images/day = $0
- **Paid:** $10/month = ~850 images/month = $0.012/image

### Alternatives
- **Pixazo:** $0.13 per image (10x more expensive)
- **Replicate:** $0.002 per image (cheaper but lower quality)
- **Gemini:** Requires Vertex AI (complex setup)

## Testing Checklist

- [ ] API key set in environment
- [ ] Flask app restarted
- [ ] Upload room photo (< 5MB)
- [ ] Check console for progress logs
- [ ] Verify image generation completes
- [ ] Download result image
- [ ] Test with different products
- [ ] Test with different room angles

## Support Resources

### Leonardo.ai
- [Documentation](https://docs.leonardo.ai)
- [API Reference](https://docs.leonardo.ai/reference)
- [Discord Community](https://discord.gg/leonardo-ai)
- [Support](https://leonardo.ai/support)

### Common Questions

**Q: How many images can I generate per day?**
A: ~15-18 with free tier (150 tokens)

**Q: Do I need a credit card?**
A: No! Free tier requires no payment info

**Q: Can I use this commercially?**
A: Yes, check [Terms of Service](https://leonardo.ai/terms)

**Q: What if I run out of tokens?**
A: Wait for daily reset or upgrade to paid plan

## Summary

✅ **FREE tier available** - Start immediately
✅ **High quality results** - Leonardo Vision XL
✅ **Simple integration** - 4-step API process
✅ **Perfect for testing** - 15+ images/day free
✅ **Scalable** - Upgrade when needed

Your AI room visualization is ready! 🚀

## Next Steps

1. ✅ Get Leonardo API key
2. ✅ Set environment variable
3. ✅ Restart Flask app
4. ✅ Test with sample room photo
5. ✅ Adjust init_strength if needed
6. ✅ Deploy to production

Happy visualizing! 🎨