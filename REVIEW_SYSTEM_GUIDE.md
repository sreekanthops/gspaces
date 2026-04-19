# Enhanced Review System Guide

## Overview
Complete review system with image/video uploads and admin controls.

## Features
- ⭐ Star ratings (1-5) with review text
- 📝 Review title and detailed comments
- 📸 Image uploads (PNG, JPG, GIF, WEBP)
- 🎥 Video uploads (MP4, WEBM, MOV)
- ✅ Admin approval/delete controls
- 👍 Helpful voting system
- ✓ Verified purchase badges

## Quick Deployment

```bash
chmod +x deploy_review_system.sh
sudo ./deploy_review_system.sh
```

## Manual Steps

1. **Create directory:**
   ```bash
   mkdir -p static/img/reviews && chmod 755 static/img/reviews
   ```

2. **Apply migration:**
   ```bash
   sudo -u postgres psql gspaces < upgrade_reviews_with_media.sql
   ```

3. **Restart app:**
   ```bash
   sudo systemctl restart gspaces
   ```

## Admin Access
- URL: `/admin/reviews`
- Configure admin emails in `main.py`: `ADMIN_EMAILS = ['admin@example.com']`

## Usage

### Customers
1. Go to product page → Reviews tab
2. Submit rating + review text + optional media (max 5 files)
3. Mark helpful reviews with thumbs up

### Admins
1. Access `/admin/reviews`
2. Approve pending reviews (green button)
3. Delete inappropriate reviews (red button)
4. Filter by status and sort by date/rating

## Files Modified
- `main.py` - Added admin routes (lines 2003-2184)
- `templates/product_detail.html` - Enhanced review form
- `templates/admin_reviews.html` - Already exists
- `upgrade_reviews_with_media.sql` - Database migration
- `deploy_review_system.sh` - Deployment script

## Troubleshooting
- **Reviews not showing:** Check if approved in admin panel
- **Upload fails:** Verify `static/img/reviews/` permissions (755)
- **Admin access denied:** Add email to `ADMIN_EMAILS` in main.py

Made with ❤️ by Bob