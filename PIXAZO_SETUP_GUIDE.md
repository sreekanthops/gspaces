# Pixazo AI Room Visualization - Setup Guide

## Overview
This guide shows you how to set up AI room visualization using Pixazo's image-to-image API. Pixazo provides high-quality image transformations perfect for visualizing furniture in customer rooms.

## Why Pixazo?
- ✅ **Simple API** - Easy to integrate
- ✅ **Multiple Models** - flux-schnell, SDXL, Stable Diffusion 1.5
- ✅ **Image-to-Image** - Perfect for room transformations
- ✅ **Fast Processing** - Quick results
- ✅ **Affordable** - Cost-effective pricing

## Setup Steps

### 1. Get Pixazo API Key
1. Visit [Pixazo](https://pixazo.ai) and sign up
2. Go to your account dashboard
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with your subscription key)

### 2. Set Environment Variable
Add to your `.env` file or export:
```bash
export PIXAZO_API_KEY="your-pixazo-api-key-here"
```

Or in your `.env` file:
```
PIXAZO_API_KEY=your-pixazo-api-key-here
```

### 3. Install Required Package
```bash
pip install requests
```

### 4. Restart Your Flask App
```bash
# Stop the current app (Ctrl+C)
# Then restart
python main.py
```

## How It Works

### 1. User Uploads Room Photo
Customer uploads a photo of their room where they want to place furniture.

### 2. API Call to Pixazo
```python
headers = {
    "Content-Type": "application/json",
    "Ocp-Apim-Subscription-Key": PIXAZO_API_KEY
}

data = {
    "prompt": "A modern desk setup in this room...",
    "input_images": ["https://your-site.com/room-image.jpg"],
    "model": "flux-schnell",  # Fast and high quality
    "strength": 0.6  # Balance between original and transformation
}

response = requests.post(
    "https://gateway.pixazo.ai/gpt-image-2-image-to-image/v1/gpt-image-2-image-to-image/generate",
    json=data,
    headers=headers
)
```

### 3. Download Generated Image
```python
result = response.json()
generated_image_url = result['output_images'][0]
image_data = requests.get(generated_image_url).content
```

## Available Models

### 1. flux-schnell (Recommended)
- **Speed:** Very Fast
- **Quality:** Excellent
- **Best for:** Quick, high-quality transformations
- **Strength:** 0.5-0.7

### 2. sdxl
- **Speed:** Medium
- **Quality:** Very High
- **Best for:** Detailed, artistic results
- **Strength:** 0.4-0.6

### 3. stable-diffusion-1.5
- **Speed:** Fast
- **Quality:** Good
- **Best for:** Standard transformations
- **Strength:** 0.5-0.8

## Strength Parameter

The `strength` parameter controls how much the image changes:

- **0.0-0.3:** Minimal changes, mostly preserves original
- **0.4-0.6:** Balanced transformation (recommended)
- **0.7-0.9:** Strong transformation, more creative
- **1.0:** Maximum transformation

## Testing the Feature

### 1. Navigate to Product Page
```
http://localhost:5000/products
```

### 2. Click "Visualize in Your Room"
On any product page, click the visualization button.

### 3. Upload Room Photo
- Choose a clear photo of your room
- Good lighting recommended
- Show the area where furniture will go

### 4. Generate Visualization
Click "Generate Visualization" and wait 10-30 seconds.

### 5. View Result
See the AI-transformed image with furniture in your room!

## Troubleshooting

### Error: "PIXAZO_API_KEY not set"
**Solution:**
```bash
export PIXAZO_API_KEY="your-key-here"
# Then restart Flask app
```

### Error: "401 Unauthorized"
**Cause:** Invalid API key
**Solution:** 
- Check your API key is correct
- Verify it's active in Pixazo dashboard
- Make sure no extra spaces in the key

### Error: "Image URL not accessible"
**Cause:** Pixazo can't access your image URL
**Solution:**
- Make sure your Flask app is publicly accessible, OR
- Use ngrok for local testing:
```bash
ngrok http 5000
# Use the ngrok URL in your app
```

### Error: "Timeout"
**Cause:** API taking too long
**Solution:**
- Increase timeout in code (currently 60 seconds)
- Try a faster model (flux-schnell)
- Reduce image size

### No Image in Response
**Check the response structure:**
```python
print(result_data)
# Look for: output_images, images, or image_url
```

## Cost Optimization

### 1. Cache Results
Store generated images to avoid regenerating:
```python
# Check if visualization exists before generating
existing = check_existing_visualization(user_id, product_id, room_hash)
if existing:
    return existing
```

### 2. Resize Images
Smaller images = faster processing = lower cost:
```python
# Already implemented - resizes to 1024x1024
```

### 3. Use Appropriate Strength
Lower strength = faster processing:
- Start with 0.5
- Increase only if needed

## Example Prompts

### For Desks
```
A modern, professional desk setup featuring a [product_name] in this room. 
Photorealistic interior design with proper lighting, shadows, and perspective. 
High resolution, detailed, naturally integrated into the existing space.
```

### For Chairs
```
An ergonomic office chair ([product_name]) placed in this workspace. 
Professional interior design with realistic lighting and shadows. 
Seamlessly integrated into the room's aesthetic.
```

### For Storage
```
A sleek storage unit ([product_name]) against the wall in this room. 
Modern interior design with natural lighting and proper perspective. 
High quality, photorealistic integration.
```

## API Response Format

### Success Response
```json
{
    "output_images": [
        "https://pixazo-cdn.com/generated-image-123.png"
    ],
    "status": "success",
    "processing_time": 15.2
}
```

### Error Response
```json
{
    "error": "Invalid API key",
    "status": "error",
    "code": 401
}
```

## Best Practices

### 1. Image Quality
- Use high-resolution room photos (min 512x512)
- Good lighting is essential
- Clear, uncluttered backgrounds work best

### 2. Prompt Engineering
- Be specific about the product
- Mention lighting and shadows
- Include "photorealistic" for better results
- Specify integration with existing space

### 3. Error Handling
- Always check response status
- Provide fallback options
- Show user-friendly error messages

### 4. User Experience
- Show loading indicator (10-30 seconds)
- Allow multiple attempts
- Save successful visualizations
- Provide before/after comparison

## Production Deployment

### 1. Environment Variables
```bash
# On your server
export PIXAZO_API_KEY="your-production-key"
export FLASK_ENV="production"
```

### 2. Public URL
Make sure your app is publicly accessible:
- Use a domain name
- Configure proper DNS
- Enable HTTPS

### 3. Image Storage
Store generated images permanently:
```python
# Already implemented in the code
# Images saved to: static/uploads/visualizations/
```

### 4. Rate Limiting
Implement rate limiting to control costs:
```python
from flask_limiter import Limiter

limiter = Limiter(app, key_func=lambda: current_user.id)

@app.route('/api/visualize/generate')
@limiter.limit("5 per hour")  # 5 visualizations per hour per user
def generate_visualization():
    # ...
```

## Support

### Pixazo Documentation
- [API Docs](https://pixazo.ai/docs)
- [Model Comparison](https://pixazo.ai/models)
- [Pricing](https://pixazo.ai/pricing)

### Common Issues
1. **Slow generation:** Use flux-schnell model
2. **Poor quality:** Increase strength or use SDXL
3. **API errors:** Check API key and quota
4. **Image not loading:** Verify URL accessibility

## Next Steps

1. ✅ Set up Pixazo API key
2. ✅ Test with a sample room photo
3. ✅ Adjust strength parameter for best results
4. ✅ Customize prompts for your products
5. ✅ Deploy to production

Your AI room visualization feature is now ready! 🎉