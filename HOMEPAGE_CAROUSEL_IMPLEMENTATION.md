# Homepage Carousel with Image Cropping - Implementation Guide

## Overview
Complete carousel system with image cropping functionality for GSpaces homepage banner management.

## Features Implemented

### 1. Database Schema ✅
- **File**: `update_banner_carousel_schema.sql`
- Added `homepage_carousel_images` table for multiple banner images
- Added carousel settings to `homepage_banner` table:
  - `enable_carousel` - Toggle carousel on/off
  - `slide_duration` - Auto-slide interval
  - `display_order` - Image ordering

### 2. Admin Interface ✅
- **File**: `templates/admin_homepage_carousel.html`
- **Features**:
  - Image upload with Cropper.js integration
  - Crop images to 1920x1080px (16:9 aspect ratio)
  - Rotate, flip, reset cropping tools
  - Multiple image management
  - Drag & drop reordering (Sortable.js)
  - Edit banner details (title, subtitle, button)
  - Delete images
  - Carousel settings (enable/disable, slide duration)

### 3. Backend Routes ✅
- **File**: `main.py`
- **Routes Added**:
  - `/admin/homepage-carousel` - Main carousel management page
  - `/admin/carousel/settings/update` - Update carousel settings
  - `/admin/carousel/image/add` - Add new cropped image
  - `/admin/carousel/image/<id>` - Get image details
  - `/admin/carousel/image/<id>/update` - Update image details
  - `/admin/carousel/image/<id>/delete` - Delete image
  - `/admin/carousel/order/update` - Update image order

### 4. Homepage Integration ✅
- **File**: `main.py` (index route updated)
- Fetches carousel settings and images
- Passes data to template

## Still TODO

### 5. Update Homepage Template
- **File**: `templates/index.html`
- Replace single banner with carousel
- Add auto-slide JavaScript
- Handle single image vs multiple images
- Ensure smooth transitions

### 6. Update Admin Sidebar
- **File**: `templates/admin_sidebar.html`
- Change "Homepage Banner" link to "Homepage Carousel"
- Update route from `admin_homepage_banner` to `admin_homepage_carousel`

## Deployment Steps

1. **Run Database Migration**:
```bash
sudo -u postgres psql -d gspaces -f update_banner_carousel_schema.sql
```

2. **Update Code**:
```bash
git pull origin newdesign
```

3. **Restart Service**:
```bash
sudo systemctl restart gspaces
```

4. **Access Admin Panel**:
- Visit: `https://gspaces.in/admin/homepage-carousel`
- Upload and crop banner images
- Enable carousel and set slide duration
- Drag to reorder images

## Technical Details

### Image Cropping
- **Library**: Cropper.js v1.6.1
- **Aspect Ratio**: 16:9 (1920x1080px)
- **Output Format**: JPEG (95% quality)
- **Features**: Rotate, flip, zoom, reset

### Carousel
- **Library**: Sortable.js v1.15.0 (for drag & drop)
- **Auto-slide**: Configurable (2-10 seconds)
- **Transitions**: Smooth fade/slide
- **Responsive**: Works on all devices

### Image Storage
- **Location**: `/static/img/`
- **Naming**: `carousel_YYYYMMDD_HHMMSS_filename.jpg`
- **Normalization**: All images cropped to same size for consistent display

## Benefits

1. **Admin Control**: Full control over homepage banner
2. **Image Quality**: Consistent 1920x1080px images
3. **Easy Management**: Drag & drop reordering
4. **Flexible**: Single image or carousel
5. **Professional**: Smooth transitions and animations
6. **Mobile Friendly**: Responsive design

## Next Steps

1. Complete homepage template carousel implementation
2. Update admin sidebar link
3. Test on live server
4. Train admin on how to use the system