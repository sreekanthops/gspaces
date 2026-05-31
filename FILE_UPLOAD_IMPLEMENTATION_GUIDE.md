# File Upload Auto-Rename Implementation Guide

## Overview
This guide explains how to integrate the new centralized file naming system (`file_upload_helper.py`) across all upload locations in the application.

## What Was Created

### 1. `file_upload_helper.py`
A centralized utility module that provides standardized filename generation for all uploads.

**Key Features:**
- Consistent naming convention: `category_identifier_counter_timestamp.ext`
- Automatic timestamp addition
- Safe filename sanitization
- Category-specific helper functions

**Example Filenames:**
```
product_123_1_20260531_143022.jpg
lead_ref_45_20260531_143022.png
lead_design_whitewash_1_20260531_143022.mp4
blog_10_2_20260531_143022.jpg
profile_user_14_20260531_143022.png
icon_desk_lamp_20260531_143022.png
```

## Implementation Steps

### Step 1: Import the Helper Module
Add this import at the top of each file that handles uploads:

```python
from file_upload_helper import (
    generate_lead_reference_filename,
    generate_lead_design_filename,
    generate_product_filename,
    generate_blog_filename,
    generate_profile_filename,
    generate_icon_filename,
    generate_review_filename,
    generate_inquiry_filename,
    generate_banner_filename,
    generate_design_gallery_filename
)
```

### Step 2: Replace Filename Generation

#### Before (Old Way):
```python
# Old manual timestamp generation
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
filename = f"ref_{timestamp}_{secure_filename(file.filename)}"
```

#### After (New Way):
```python
# New centralized naming
filename = generate_lead_reference_filename(lead_id, file.filename)
```

## File-by-File Integration Guide

### 1. **leads_simple.py**

#### Location 1: Reference Image Upload (Line ~575)
```python
# OLD:
filename = f"ref_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_lead_reference_filename(lead_id, file.filename)
```

#### Location 2: Design Media Upload (Line ~779)
```python
# OLD:
filename = f"design_{lead_id}_{idx+1}_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_lead_design_filename(design_name, idx+1, file.filename)
```

#### Location 3: Icon Upload (Line ~1445)
```python
# OLD:
filename = f"icon_{item_slug}_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_icon_filename(item_name, file.filename)
```

### 2. **main.py**

#### Location 1: Profile Photo (Line ~1528)
```python
# OLD:
profile_filename = f"user_{user_id}_{int(time.time())}.{ext}"

# NEW:
profile_filename = generate_profile_filename(user_id, profile_photo.filename)
```

#### Location 2: Product Main Image (Line ~1638)
```python
# OLD:
main_filename = f"main_{timestamp}_{secure_filename(main_image.filename)}"

# NEW:
main_filename = generate_product_filename(product_id, 1, main_image.filename)
```

#### Location 3: Product Sub Images (Line ~1649)
```python
# OLD:
sub_filename = f"sub_{idx}_{timestamp}_{secure_filename(sub_img.filename)}"

# NEW:
sub_filename = generate_product_filename(product_id, idx+2, sub_img.filename)
```

#### Location 4: Review Images (Line ~1997)
```python
# OLD:
unique_filename = f"review_{product_id}_{review_id}_{idx}_{timestamp}_{secure_filename(media_file.filename)}"

# NEW:
unique_filename = generate_review_filename(product_id, review_id, idx+1, media_file.filename)
```

#### Location 5: Customer Inquiry Files (Line ~4412)
```python
# OLD:
new_filename = f"inquiry_{inquiry_id}_{timestamp}_{secure_filename(file.filename)}"

# NEW:
new_filename = generate_inquiry_filename(inquiry_id, file_idx+1, file.filename)
```

#### Location 6: Homepage Banner (Line ~4678)
```python
# OLD:
filename = f"banner_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_banner_filename(banner_id, file.filename)
```

#### Location 7: Carousel Image (Line ~4833)
```python
# OLD:
filename = f"carousel_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_banner_filename(carousel_id, file.filename)
```

### 3. **blog_routes.py**

#### Location 1: Blog Images (Line ~300)
```python
# OLD:
filename = f"blog_{blog_id}_{image_count}_{timestamp}_{secure_filename(img.filename)}"

# NEW:
filename = generate_blog_filename(blog_id, image_count+1, img.filename)
```

#### Location 2: Blog Video (Line ~316)
```python
# OLD:
filename = f"blog_{blog_id}_video_{timestamp}_{secure_filename(video.filename)}"

# NEW:
filename = generate_blog_filename(blog_id, 'video', video.filename)
```

### 4. **design_gallery_routes.py**

#### Location 1: Gallery Image (Line ~106)
```python
# OLD:
filename = f"gallery_{timestamp}_{secure_filename(file.filename)}"

# NEW:
filename = generate_design_gallery_filename(design_id, 1, file.filename)
```

#### Location 2: Additional Gallery Image (Line ~582)
```python
# OLD:
filename = f"gallery_{design_id}_{timestamp}_{secure_filename(file.filename)}"

# NEW:
# Get current image count for this design
cur.execute("SELECT COUNT(*) FROM design_gallery_images WHERE design_id = %s", (design_id,))
count = cur.fetchone()[0]
filename = generate_design_gallery_filename(design_id, count+1, file.filename)
```

### 5. **ai_visualization_routes.py**

#### Location 1: Reference/Target Images (Line ~93-94)
```python
# OLD:
ref_filename = f"ref_{timestamp}_{secure_filename(reference_image.filename)}"
target_filename = f"target_{timestamp}_{secure_filename(target_image.filename)}"

# NEW:
ref_filename = generate_furniture_filename(f"ref_{session_id}", reference_image.filename)
target_filename = generate_furniture_filename(f"target_{session_id}", target_image.filename)
```

## Testing Checklist

After implementing the changes, test each upload location:

- [ ] Lead reference image upload
- [ ] Lead design media upload (images and videos)
- [ ] Default item icon upload
- [ ] Product main image upload
- [ ] Product sub-images upload
- [ ] Product review media upload
- [ ] User profile photo upload
- [ ] Blog images and videos upload
- [ ] Customer inquiry file upload
- [ ] Homepage banner/carousel upload
- [ ] Design gallery image upload
- [ ] AI visualization image upload

## Benefits

1. **Consistency**: All files follow the same naming pattern
2. **Traceability**: Filenames include category, ID, and timestamp
3. **Organization**: Easy to identify file source and purpose
4. **Collision Prevention**: Timestamp ensures unique filenames
5. **Maintainability**: Centralized logic, easy to update
6. **Debugging**: Clear filename structure helps troubleshooting

## Migration Notes

### Backward Compatibility ⚠️ IMPORTANT
**The new naming system ONLY affects NEW uploads. Existing images are NOT changed.**

#### How It Works:
1. **Existing Images**: All current images remain with their original filenames
   - Database still points to old filenames (e.g., `ref_20260503_135754_baji.jpg`)
   - Files on disk keep their original names
   - Website continues to display them correctly
   - **NO BROKEN IMAGES** - Everything works as before

2. **New Uploads**: Only new files uploaded AFTER implementation get new names
   - New format: `lead_ref_6_20260531_143022.jpg`
   - Saved to database with new filename
   - Website displays them correctly

#### Example:
```
Before Implementation:
- Database: reference_image = "img/leads/reference/ref_20260503_135754_baji.jpg"
- Disk: /static/img/leads/reference/ref_20260503_135754_baji.jpg
- Website: ✅ Shows image correctly

After Implementation (existing image):
- Database: reference_image = "img/leads/reference/ref_20260503_135754_baji.jpg" (UNCHANGED)
- Disk: /static/img/leads/reference/ref_20260503_135754_baji.jpg (UNCHANGED)
- Website: ✅ Still shows image correctly (NO CHANGE)

After Implementation (new upload):
- Database: reference_image = "img/leads/reference/lead_ref_10_20260531_143022.png" (NEW FORMAT)
- Disk: /static/img/leads/reference/lead_ref_10_20260531_143022.png (NEW FORMAT)
- Website: ✅ Shows new image correctly
```

### Database Impact
- **No database schema changes required**
- **No data migration needed**
- **File paths stored in database remain unchanged for existing records**
- Only new records will have new filename format
- Both old and new formats coexist perfectly

### Why This Is Safe:
1. We're NOT renaming existing files on disk
2. We're NOT updating existing database records
3. We're ONLY changing how NEW files are named when uploaded
4. The code that displays images doesn't care about filename format - it just uses the path from database

## Deployment Steps

1. **Upload `file_upload_helper.py`** to the server
2. **Update each Python file** with the new import and function calls
3. **Test in development** environment first
4. **Deploy to production** after successful testing
5. **Monitor logs** for any file upload errors

## Rollback Plan

If issues occur:
1. Keep `file_upload_helper.py` on server (no harm)
2. Revert the import statements and function calls
3. Files uploaded with new names will still be accessible
4. Fix issues and redeploy

## Support

For questions or issues:
- Email: sreekanth.chityala@gspaces.in
- Phone: +91 7075077384

---

**Created**: May 31, 2026
**Version**: 1.0
**Status**: Ready for Implementation