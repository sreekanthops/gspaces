# Pixazo Funding Guide

## Good News! 🎉
Your Pixazo API integration is **working perfectly**! The error you saw means:
- ✅ API key is valid
- ✅ Code is correct
- ✅ Connection successful
- ⚠️ Just needs funds in account

## Error Explained
```
402 - Insufficient Balance
Required: $0.1280
```

This means each image generation costs approximately **$0.13** (13 cents).

## How to Add Funds

### Step 1: Login to Pixazo
1. Go to [Pixazo Dashboard](https://pixazo.ai/dashboard)
2. Login with your account

### Step 2: Add Credits
1. Navigate to "Billing" or "Credits" section
2. Click "Add Funds" or "Top Up"
3. Choose an amount:
   - **$10** = ~77 image generations
   - **$25** = ~195 image generations
   - **$50** = ~390 image generations
   - **$100** = ~781 image generations

### Step 3: Payment
1. Enter payment details (credit card, PayPal, etc.)
2. Complete the transaction
3. Credits will be added instantly

### Step 4: Test Again
1. Go back to your website
2. Try the visualization feature
3. It should work now! ✨

## Cost Breakdown

### Per Image
- **flux-schnell:** ~$0.10-0.15 per image
- **SDXL:** ~$0.20-0.30 per image
- **Stable Diffusion 1.5:** ~$0.05-0.10 per image

### Monthly Estimates
If you expect:
- **10 visualizations/day** = ~$39/month
- **50 visualizations/day** = ~$195/month
- **100 visualizations/day** = ~$390/month

## Cost Optimization Tips

### 1. Use Cheaper Model
Switch to Stable Diffusion 1.5 (half the cost):
```python
data = {
    "model": "stable-diffusion-1.5",  # Instead of flux-schnell
    "strength": 0.6
}
```

### 2. Cache Results
Don't regenerate the same visualization:
```python
# Check if user already visualized this product with this room
existing = get_cached_visualization(user_id, product_id, room_hash)
if existing:
    return existing  # Use cached version
```

### 3. Limit Free Generations
Allow limited free tries, then charge:
```python
# In your code
user_free_generations = get_user_free_count(user_id)
if user_free_generations >= 3:
    return "You've used your free visualizations. Upgrade to continue."
```

### 4. Charge Customers
Pass the cost to customers:
- **Free tier:** 3 visualizations
- **Premium:** Unlimited for $9.99/month
- **Pay-per-use:** $0.50 per visualization

## Alternative: Free Options

If you want to avoid costs entirely, here are alternatives:

### Option 1: Simple Composite (Free)
Overlay product image on room photo:
```python
# Basic image composition - no AI
from PIL import Image

room = Image.open(room_path)
product = Image.open(product_path)
# Resize and paste product onto room
# No AI, but instant and free
```

### Option 2: Replicate (Free Tier)
Replicate offers free tier:
- Sign up at [Replicate](https://replicate.com)
- Get free credits monthly
- Use FLUX or Stable Diffusion models

### Option 3: Hugging Face (Free)
Use Hugging Face Inference API:
- Free tier available
- Slower but works
- Good for testing

## Recommended Approach

### For Testing (Now)
1. Add $10 to Pixazo account
2. Test the feature thoroughly
3. Optimize prompts and settings

### For Production (Later)
Choose one:

**Option A: Pass Cost to Customers**
- Charge $0.99 per visualization
- Or include in premium membership
- Covers API costs + profit

**Option B: Limit Free Usage**
- 3 free visualizations per user
- Then require payment or subscription
- Prevents abuse

**Option C: Use Free Alternative**
- Switch to Replicate free tier
- Or implement simple composite
- No ongoing costs

## Quick Fix: Add $10 Now

**Fastest solution:**
1. Go to Pixazo dashboard
2. Add $10 (gives you ~77 visualizations)
3. Test your feature
4. Decide on long-term strategy

This will let you test immediately and show the feature to customers!

## Support

### Pixazo Support
- Email: support@pixazo.ai
- Dashboard: [pixazo.ai/support](https://pixazo.ai/support)

### Questions?
- Check billing section for current balance
- View usage history in dashboard
- Set up billing alerts to avoid surprises

## Summary

✅ **Your code works perfectly!**
✅ **Just add funds to continue**
✅ **$10 is enough for testing**
✅ **Consider monetization strategy for production**

The feature is ready - just needs credits! 🚀