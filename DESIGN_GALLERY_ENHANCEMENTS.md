# Design Gallery Enhancements Documentation

## Overview
This document describes all the enhancements made to the design gallery system, including video handling, dynamic categories, media management, and the new "type" field for lead designs.

## Features Implemented

### 1. Video Completion Detection & Auto-Slide Control

#### Design Gallery View Page (`templates/design_gallery_view.html`)
- **Video Completion Detection**: Auto-slide now waits for videos to complete before advancing to the next slide
- **Play/Pause Button**: Added a circular button at bottom-left to control auto-slide
  - Shows pause icon (⏸) when playing
  - Shows play icon (▶) when paused
  - Keyboard shortcut: Spacebar to toggle
- **Video Event Handling**: When a video ends, automatically advances to next slide

#### Quotation View Page (`templates/quotation_view_simple.html`)
- **Play/Pause Button**: Each design carousel now has its own play/pause control
- **Per-Carousel State**: Each carousel maintains independent auto-slide state
- **Video-Aware Scrolling**: Already had video completion detection, now enhanced with manual controls

### 2. Dynamic Categories

#### Backend Changes (`design_gallery_routes.py`)
- **Dynamic Category Fetching**: Categories are now fetched from active designs in the database
- **Removed Hardcoded Categories**: No more hardcoded "commercial" category
- **Category Count**: Shows number of designs per category

#### Frontend Changes (`templates/design_gallery_public.html`)
- **Dynamic Category Buttons**: Category filter buttons are generated from database
- **Fallback Categories**: If no categories found, shows default: Office, Home, Studio
- **Auto-Generated**: New categories automatically appear when designs are added

### 3. Auto-Play Carousel on Hover

#### Public Gallery (`templates/design_gallery_public.html`)
- **Hover-Activated Carousel**: When hovering over a design card with multiple media, carousel auto-plays
- **Video Support**: Videos play automatically during carousel
- **Smooth Transitions**: 2-second intervals between slides
- **Reset on Leave**: Returns to first slide when mouse leaves

#### Implementation Details
```javascript
// Mini carousel states tracked per design
miniCarouselStates[designId] = {
    currentSlide: 0,
    totalSlides: totalSlides,
    interval: null,
    isPlaying: false
};
```

### 4. Type Field for Lead Designs

#### Database Schema (`enhance_design_gallery_features.sql`)
```sql
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS type VARCHAR(100);
```

#### Purpose
- Categorize designs by setup type
- Examples: "Work from Home Setup", "Studio Setup", "Office Setup"
- Allows custom types entered by admin
- Default value: "Office Setup"

#### Usage
- Displayed in design gallery view
- Can be filtered/searched
- Helps customers find relevant designs

### 5. Media Management System

#### New Routes (`design_gallery_routes.py`)

**Manage Media Page**
```python
@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/manage-media')
```
- View all media for a design
- Upload additional images/videos
- Set primary thumbnail
- Delete media

**Set Primary Image**
```python
@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/set-primary/<int:image_id>')
```
- Mark an image as primary
- Automatically updates design_gallery.image_url
- Unsets previous primary image

#### Database Trigger
```sql
CREATE TRIGGER trigger_sync_primary_image
    AFTER INSERT OR UPDATE OF is_primary ON design_images
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION sync_primary_image_to_gallery();
```

### 6. Enhanced Design Gallery Routes

#### Public Gallery Enhancements
- **All Media Fetching**: Each design includes all its media files
- **Type Information**: Includes design type from lead_designs
- **Image Count**: Shows total media count per design
- **Fallback Handling**: If no media in design_images, uses main image_url

## Database Schema Changes

### New Tables
```sql
CREATE TABLE IF NOT EXISTS design_images (
    id SERIAL PRIMARY KEY,
    design_id INTEGER NOT NULL REFERENCES design_gallery(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    video_url TEXT,
    thumbnail_url TEXT,
    media_type VARCHAR(20) DEFAULT 'image',
    display_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Modified Tables
```sql
-- lead_designs
ALTER TABLE lead_designs ADD COLUMN type VARCHAR(100);

-- Indexes added
CREATE INDEX idx_design_images_design_id ON design_images(design_id);
CREATE INDEX idx_design_images_primary ON design_images(design_id, is_primary);
CREATE INDEX idx_lead_designs_type ON lead_designs(type);
CREATE INDEX idx_design_gallery_category ON design_gallery(category);
```

### Helper Functions
```sql
-- Get active categories with counts
CREATE FUNCTION get_active_design_categories()
RETURNS TABLE(category VARCHAR, design_count BIGINT);

-- Get active types with counts
CREATE FUNCTION get_active_design_types()
RETURNS TABLE(type VARCHAR, design_count BIGINT);
```

## File Changes Summary

### Modified Files
1. `templates/design_gallery_view.html` - Video completion + play/pause
2. `templates/quotation_view_simple.html` - Carousel play/pause
3. `templates/design_gallery_public.html` - Dynamic categories + hover carousel
4. `design_gallery_routes.py` - Enhanced routes + media management

### New Files
1. `enhance_design_gallery_features.sql` - Database migrations
2. `add_type_field_to_leads.sql` - Type field migration
3. `deploy_design_gallery_enhancements.sh` - Deployment script
4. `DESIGN_GALLERY_ENHANCEMENTS.md` - This documentation

## Deployment Instructions

### Step 1: Run Database Migrations
```bash
psql -U sri -d gspaces -f enhance_design_gallery_features.sql
```

### Step 2: Restart Application
```bash
sudo systemctl restart gspaces
```

### Step 3: Verify Changes
```bash
# Check type field
psql -U sri -d gspaces -c "SELECT id, type FROM lead_designs LIMIT 5;"

# Check design_images table
psql -U sri -d gspaces -c "\d design_images"

# Check active categories
psql -U sri -d gspaces -c "SELECT * FROM get_active_design_categories();"
```

### Or Use Deployment Script
```bash
chmod +x deploy_design_gallery_enhancements.sh
./deploy_design_gallery_enhancements.sh
```

## Testing Checklist

### Public Gallery (`/designs`)
- [ ] Categories are dynamically loaded
- [ ] No "Commercial" button (unless designs exist with that category)
- [ ] Hover over multi-media designs shows carousel
- [ ] Videos play during carousel
- [ ] Carousel stops when mouse leaves
- [ ] Click opens design detail page

### Design Detail Page (`/designs/<id>`)
- [ ] Play/pause button appears (bottom-left)
- [ ] Button toggles auto-slide
- [ ] Videos complete before advancing
- [ ] Spacebar toggles play/pause
- [ ] Arrow keys navigate slides

### Quotation Page
- [ ] Each design carousel has play/pause button
- [ ] Buttons work independently
- [ ] Videos complete before advancing
- [ ] Manual navigation resets auto-slide timer

### Admin Features (To Be Implemented)
- [ ] Add "type" field to lead creation form
- [ ] Create media management page
- [ ] Test primary image selection
- [ ] Test media upload
- [ ] Test media deletion

## Next Steps

### 1. Update Admin Lead Form
Add "type" field to `templates/admin_leads_simple.html` or equivalent:
```html
<div class="mb-3">
    <label for="type" class="form-label">Setup Type</label>
    <input type="text" class="form-control" id="type" name="type" 
           placeholder="e.g., Work from Home Setup, Studio Setup">
    <small class="text-muted">Or select: Office Setup, Studio Setup, WFH Setup</small>
</div>
```

### 2. Create Media Management Template
Create `templates/admin_design_media.html` for managing design media.

### 3. Add Media Upload to Admin Gallery
Update `templates/admin_design_gallery.html` to include "Manage Media" button for each design.

## API Endpoints

### Public Endpoints
- `GET /designs` - Public gallery with dynamic categories
- `GET /designs/<id>` - Design detail with all media

### Admin Endpoints
- `GET /admin/design-gallery` - Admin gallery management
- `POST /admin/design-gallery/add` - Add new design
- `POST /admin/design-gallery/<id>/update` - Update design
- `POST /admin/design-gallery/<id>/delete` - Delete design
- `POST /admin/design-gallery/<id>/toggle` - Toggle active status
- `GET /admin/design-gallery/<id>/manage-media` - Media management page
- `POST /admin/design-gallery/<id>/set-primary/<image_id>` - Set primary image
- `POST /admin/design-gallery/<id>/add-image` - Upload additional media
- `POST /admin/design-gallery/image/<id>/delete` - Delete media

## Technical Notes

### Video Handling
- Videos must be in MP4 format
- Muted by default in carousels
- Auto-play on carousel advance
- Pause when slide changes

### Performance Considerations
- Carousels only initialize for designs with multiple media
- Videos lazy-load
- Intervals cleared when not in use
- Database queries optimized with indexes

### Browser Compatibility
- Tested on Chrome, Firefox, Safari
- Requires JavaScript enabled
- CSS Grid and Flexbox used
- Modern ES6 JavaScript

## Troubleshooting

### Carousel Not Auto-Playing
- Check browser console for errors
- Verify design has multiple media
- Check if JavaScript is enabled

### Videos Not Playing
- Verify video format (MP4)
- Check video file paths
- Ensure videos are accessible

### Categories Not Showing
- Verify designs exist in database
- Check if designs are active
- Run `get_active_design_categories()` function

### Type Field Not Saving
- Verify database migration ran
- Check column exists: `\d lead_designs`
- Verify form includes type field

## Support
For issues or questions, contact the development team or refer to the main project documentation.