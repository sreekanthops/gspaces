# AI Room Visualization - Usage Guide

## Overview
The AI Room Visualization feature allows customers to see how your furniture products would look in their own rooms using AI image transformation powered by Google's Imagen API.

## Prerequisites

### 1. Install Required Package
```bash
pip install google-genai
```

### 2. Get Google AI API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key

### 3. Set Environment Variable
```bash
export GEMINI_API_KEY="your-api-key-here"
```

Or add to your `.env` file:
```
GEMINI_API_KEY=your-api-key-here
```

### 4. Create Database Table
Run this SQL to create the visualizations table:
```sql
CREATE TABLE IF NOT EXISTS room_visualizations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    room_image_url TEXT NOT NULL,
    result_image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## How to Use (Customer Perspective)

### Step 1: Browse Products
1. Go to your website and browse furniture products
2. Find a desk or furniture item you're interested in

### Step 2: Access Visualization
1. Click the "Visualize in Your Room" button on the product page
2. You'll be taken to the visualization page

### Step 3: Upload Room Photo
1. Click "Choose File" or "Upload Room Photo"
2. Select a photo of your room where you want to place the furniture
3. **Tips for best results:**
   - Use good lighting
   - Take photo from a clear angle
   - Make sure the area where furniture will go is visible
   - Avoid cluttered backgrounds

### Step 4: Generate Visualization
1. Click "Generate Visualization"
2. Wait 10-30 seconds for AI processing
3. The AI will transform your room photo to show the furniture in place

### Step 5: View Results
1. See the before/after comparison
2. Download the result if you like it
3. Try different angles or rooms

## How It Works (Technical)

### 1. Image Upload
```python
# User uploads room photo
room_image = request.files.get('room_image')
```

### 2. Image Processing
```python
# Resize to optimal size (1024x1024)
base_image = Image.open(room_path)
base_image = base_image.resize((1024, 1024))
```

### 3. AI Transformation
```python
# Use Imagen API to edit the image
response = client.models.edit_image(
    model="imagen-3.0-capability-001",
    image=base_image,
    prompt="Transform this room to include a professional desk setup...",
    config=types.GenerateImageConfig(
        number_of_images=1,
        include_rai_reasoning=True
    )
)
```

### 4. Save Result
```python
# Save the AI-generated image
generated_image = response.generated_images[0].image
generated_image.save(result_path)
```

## API Endpoints

### 1. Visualization Page
```
GET /visualize/<product_id>
```
Shows the visualization interface for a specific product.

### 2. Generate Visualization
```
POST /api/visualize/generate
```
**Parameters:**
- `product_id`: ID of the product to visualize
- `room_image`: File upload of room photo

**Response:**
```json
{
    "status": "success",
    "visualization_id": 123,
    "result_image_url": "/static/uploads/visualizations/result_123.png",
    "message": "Visualization generated successfully!"
}
```

### 3. View History
```
GET /api/visualize/history
```
Returns user's previous visualizations.

### 4. Delete Visualization
```
DELETE /api/visualize/delete/<visualization_id>
```
Deletes a specific visualization.

## Troubleshooting

### Error: "GEMINI_API_KEY not set"
**Solution:** Set the environment variable:
```bash
export GEMINI_API_KEY="your-key-here"
```

### Error: "404 NOT_FOUND"
**Solution:** The code now uses the correct `edit_image` method. Make sure you have the latest version.

### Error: "429 RESOURCE_EXHAUSTED"
**Solution:** You've exceeded your API quota. Either:
- Wait for quota to reset (usually daily)
- Upgrade to a paid plan
- Use a different API key

### Error: "No Imagen models found"
**Solution:** Your API key might not have access to Imagen. Check:
1. API key is valid
2. Imagen API is enabled in your Google Cloud project
3. You have the correct permissions

### Images Not Generating
**Check the logs for:**
```
📋 Checking available Imagen models...
  ✅ imagen-3.0-capability-001 | Methods: ['edit_image']
```

If no models are listed, your API key doesn't have Imagen access.

## Best Practices

### For Customers
1. **Good lighting** - Take photos in well-lit rooms
2. **Clear space** - Show the area where furniture will go
3. **Straight angle** - Take photos from eye level
4. **High resolution** - Use at least 1024x1024 pixels

### For Developers
1. **Rate limiting** - Implement rate limits to avoid quota exhaustion
2. **Caching** - Cache results to avoid regenerating same visualizations
3. **Error handling** - Show user-friendly error messages
4. **Image optimization** - Resize images before sending to API

## Cost Considerations

### Google AI Studio (Free Tier)
- **Free quota:** 60 requests per minute
- **Cost after free tier:** ~$0.01-0.05 per image generation
- **Best for:** Testing and small-scale use

### Production Recommendations
1. Monitor API usage
2. Set up billing alerts
3. Implement caching
4. Consider batch processing

## Example Integration

### Add Button to Product Page
```html
<a href="/visualize/{{ product.id }}" class="btn btn-primary">
    <i class="fas fa-magic"></i> Visualize in Your Room
</a>
```

### JavaScript for Upload
```javascript
document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = new FormData();
    formData.append('product_id', productId);
    formData.append('room_image', fileInput.files[0]);
    
    const response = await fetch('/api/visualize/generate', {
        method: 'POST',
        body: formData
    });
    
    const result = await response.json();
    if (result.status === 'success') {
        showResult(result.result_image_url);
    }
});
```

## Support

If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify your API key is valid
3. Ensure all dependencies are installed
4. Check the database table exists

For more help, refer to:
- [Google AI Studio Documentation](https://ai.google.dev/docs)
- [Imagen API Reference](https://ai.google.dev/api/imagen)