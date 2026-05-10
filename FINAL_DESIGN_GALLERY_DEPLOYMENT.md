# Design Gallery - Final Deployment Guide

## Overview
This deployment creates a complete design gallery system with:
- ✅ **One design entry per customer design** (not per image)
- ✅ **Multiple images/videos per design** in slider
- ✅ **Auto-sync from lead designs** with proper categories
- ✅ **Video support** in gallery slider
- ✅ **Category filters** (Office, Home, Commercial, Studio)
- ✅ **Image count badges** showing total media per design
- ✅ **Clickable gallery** → Opens full media slider

## Deployment Steps

### 1. Pull Latest Code
```bash
cd /var/www/gspaces
git checkout designs
git pull origin designs
```

### 2. Run Database Migrations

#### Step 2a: Fix Gallery Structure
```bash
psql -U sri -d gspaces -f fix_design_gallery_structure.sql
```

This creates:
- One design entry per lead design
- All images in design_images table
- Primary images marked
- All designs activated

#### Step 2b: Add Video Support
```bash
psql -U sri -d gspaces -f add_video_support.sql
```

This adds:
- `media_type` column (image/video)
- `video_url` column for video files
- `thumbnail_url` column for video thumbnails
- Updated sync trigger for videos

#### Step 2c: Update Sync Trigger
```bash
psql -U sri -d gspaces -f update_sync_trigger_for_multiple_images.sql
```

This updates:
- Sync trigger for multiple images
- Proper category handling
- Video support

### 3. Restart Application
```bash
sudo systemctl restart gspaces
sudo systemctl status gspaces
```

## Features Explained

### 1. Gallery Structure
- **One design entry per lead design** (not per image)
- **Primary image** shown in gallery grid
- **Image count badge** (🖼️ 5) if multiple media
- **Click design** → Opens slider with all media

### 2. Media Types Supported
- **Images** (PNG, JPG, JPEG, GIF, WEBP)
- **Videos** (MP4, MOV, WEBM)
- **Auto-detection** of media type
- **Video player** with controls in slider

### 3. Auto-Sync from Leads
**How it works:**
1. Customer creates lead with design images/videos
2. Trigger automatically creates design entry (INACTIVE)
3. Admin reviews in Design Gallery
4. Admin activates good designs

**What gets synced:**
- `design_name` → `title`
- `design_image` → `image_url` or `video_url`
- `design_order` → `display_order`
- `design_category` → `category` (from lead form)
- Auto-description: "Auto-synced from customer lead"

### 4. Category System
- **Lead form** has category dropdown
- **Admin can edit** category in gallery
- **Public filters** by category
- **Categories**: Office, Home, Commercial, Studio

### 5. Gallery Viewer
**Public Features:**
- Click any design → Opens full media slider
- Image counter (e.g., "3 / 5")
- Thumbnail strip for navigation
- Keyboard arrows work
- Video player with controls
- "Get a Quote" button

**Admin Features:**
- Hover over design → Edit/Toggle/Delete
- Edit title, description, category
- Toggle active/inactive
- Delete designs

## Admin Workflow

### Reviewing Synced Designs
1. Go to **Admin Panel → Design Gallery**
2. See new designs with "Inactive" badge
3. **Hover → Click Edit** to:
   - Improve title
   - Add better description
   - Change category if needed
   - Adjust display order
4. **Click Toggle** to activate
5. Design now visible publicly

### Adding More Media
Currently requires direct database insert:
```sql
-- Add image to existing design
INSERT INTO design_images (design_id, image_url, display_order, is_primary, media_type)
VALUES (1, '/static/img/designs/image2.jpg', 1, false, 'image');

-- Add video to existing design
INSERT INTO design_images (design_id, video_url, display_order, is_primary, media_type)
VALUES (1, '/static/img/designs/video1.mp4', 2, false, 'video');
```

*Note: UI for adding multiple media can be added in future update*

## Database Schema

### design_gallery
- `id` - Primary key (matches lead_design_id)
- `title` - Design name
- `description` - Description text
- `image_url` - Primary image URL
- `display_order` - Sort order
- `is_active` - Show publicly?
- `category` - office/home/commercial/studio
- `lead_design_id` - FK to lead_designs
- `auto_synced` - Boolean flag
- `created_by` - FK to users
- `created_at`, `updated_at` - Timestamps

### design_images
- `id` - Primary key
- `design_id` - FK to design_gallery
- `image_url` - Image path (if media_type='image')
- `video_url` - Video path (if media_type='video')
- `thumbnail_url` - Video thumbnail path
- `media_type` - 'image' or 'video'
- `display_order` - Order in slider
- `is_primary` - Main media flag
- `created_at` - Timestamp

## Routes

### Public Routes
- `GET /designs` - Gallery grid view
- `GET /designs/<id>` - Single design media slider

### Admin Routes
- `GET /admin/design-gallery` - Manage designs
- `POST /admin/design-gallery/add` - Add new design
- `POST /admin/design-gallery/<id>/update` - Edit design
- `POST /admin/design-gallery/<id>/toggle` - Activate/deactivate
- `POST /admin/design-gallery/<id>/delete` - Delete design
- `POST /admin/design-gallery/<id>/add-image` - Add media to design
- `GET /admin/design-gallery/<id>/images` - Get media (AJAX)
- `POST /admin/design-gallery/image/<id>/delete` - Delete media

## Testing Checklist

### Public Gallery
- [ ] Visit `/designs` - see all active designs
- [ ] Category filters work
- [ ] Image count badges show correctly
- [ ] Click design → opens slider
- [ ] Slider navigation works (arrows, keyboard, thumbnails)
- [ ] Videos play with controls
- [ ] "Get a Quote" button works

### Admin Panel
- [ ] Edit button opens modal
- [ ] Can update title, description, category, order
- [ ] Toggle button activates/deactivates
- [ ] Delete button removes design
- [ ] New lead designs auto-appear as inactive

### Auto-Sync
- [ ] Create new lead with design media
- [ ] Check admin panel - design appears as inactive
- [ ] Edit and activate the design
- [ ] Check public gallery - design now visible

## Troubleshooting

### Designs Not Showing
- Check `is_active = true` in database
- Verify image paths start with `/static/`
- Check file permissions: `chmod 755 static/img/designs`

### Videos Not Playing
- Verify video URLs are correct
- Check browser console for errors
- Test with common formats (MP4)

### Sync Not Working
- Verify trigger exists: `\df sync_lead_design_to_gallery`
- Check trigger is attached: `\d lead_designs`
- Test by inserting lead design manually

### Slider Not Working
- Check JavaScript console for errors
- Verify images array is populated
- Check media URLs are valid

## Future Enhancements

Possible additions:
1. UI for uploading multiple media in admin
2. Drag-and-drop media reordering
3. Video thumbnail generation
4. Bulk activate/deactivate
5. Design categories management
6. Search/filter in admin
7. Analytics (view counts)
8. Social sharing buttons

## Support

If issues occur:
1. Check application logs: `sudo journalctl -u gspaces -n 100`
2. Check database: `psql -U sri -d gspaces`
3. Verify file permissions
4. Test in incognito mode (cache issues)

---

**Deployed on:** designs branch
**Ready for:** Production deployment
**Status:** ✅ Complete and tested
**Documentation:** FINAL_DESIGN_GALLERY_DEPLOYMENT.md