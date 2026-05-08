# Animated Furniture Banner Deployment Guide

## Overview
This feature creates an interactive homepage banner where furniture items (chairs, tables, plants, etc.) scatter on page load and users can drag them to arrange their perfect space.

## Features
- ✨ Scatter animation on page load
- 🖱️ Drag and drop furniture items
- 🎨 Customizable animation settings
- 📱 Mobile-friendly touch support
- 🔄 Reset button to restore original layout
- ⚙️ Admin interface for managing furniture items
- 🎯 Snap-to-grid option
- 🌈 Customizable background color

## Files Created/Modified

### New Files:
1. `create_animated_furniture_table.sql` - Database schema
2. `static/js/animated-banner.js` - Interactive animation JavaScript
3. `templates/admin_animated_furniture.html` - Admin management interface

### Modified Files:
1. `main.py` - Added 8 new routes for furniture management
2. `templates/index.html` - Will need to add animated banner section
3. `templates/admin_sidebar.html` - Will need to add menu link

## Deployment Steps

### Step 1: Create Database Tables
```bash
psql -U your_username -d gspaces -f create_animated_furniture_table.sql
```

This creates:
- `animated_furniture_items` table - Stores furniture PNG items
- `animated_banner_settings` table - Configuration settings
- Sample furniture items (replace with actual images)

### Step 2: Create Furniture Images Directory
```bash
mkdir -p static/images/furniture
```

### Step 3: Upload Furniture PNG Images
Upload PNG images with transparent backgrounds to `static/images/furniture/`:
- chair1.png, chair2.png, etc.
- desk1.png, table1.png, etc.
- plant1.png, plant2.png, etc.
- lamp1.png, lamp2.png, etc.
- shelf1.png, bookshelf1.png, etc.

**Image Requirements:**
- Format: PNG with transparent background
- Recommended size: 100-500px width/height
- Keep file sizes optimized (<200KB per image)

### Step 4: Update Admin Sidebar
Add this link to `templates/admin_sidebar.html`:

```html
<li class="nav-item">
    <a class="nav-link" href="{{ url_for('admin_animated_furniture') }}">
        <i class="fas fa-magic"></i> 🎨 Animated Furniture
    </a>
</li>
```

### Step 5: Update Homepage Template
Add this section to `templates/index.html` (before or after the carousel):

```html
{% if animated_settings and animated_settings.is_enabled and animated_items %}
<!-- Animated Furniture Banner -->
<section id="animated-furniture-banner" class="animated-furniture-section">
    <div class="container-fluid p-0">
        <div id="animated-furniture-container" style="position: relative; min-height: 500px; background: {{ animated_settings.background_color }};">
            <!-- Furniture items will be dynamically added here by JavaScript -->
        </div>
    </div>
</section>

<!-- Pass data to JavaScript -->
<script>
    window.furnitureData = {{ animated_items | tojson }};
    window.bannerSettings = {{ animated_settings | tojson }};
</script>
<script src="{{ url_for('static', filename='js/animated-banner.js') }}"></script>
{% endif %}
```

### Step 6: Test the Application
```bash
# Restart Flask application
sudo systemctl restart gspaces

# Or if running manually:
python main.py
```

### Step 7: Access Admin Interface
1. Navigate to `/admin/animated-furniture`
2. Configure animation settings:
   - Enable/disable animation
   - Set scatter duration (ms)
   - Choose easing function
   - Enable/disable dragging
   - Enable snap-to-grid
   - Set background color
3. Add furniture items:
   - Upload PNG images
   - Set dimensions (width/height)
   - Set initial position (X%, Y%)
   - Set scatter distance
   - Set rotation angle

## Configuration Options

### Animation Settings:
- **Enable Animation**: Turn the feature on/off
- **Scatter Duration**: How long the scatter animation takes (500-5000ms)
- **Easing Function**: Animation timing (ease, ease-in, ease-out, ease-in-out, linear)
- **Allow Drag**: Enable/disable user dragging
- **Snap to Grid**: Snap items to grid when dragging
- **Grid Size**: Grid cell size in pixels (10-50px)
- **Show Reset Button**: Display reset button to restore layout
- **Background Color**: Banner background color

### Furniture Item Properties:
- **Name**: Item display name
- **Category**: chair, table, plant, lamp, storage, decor, other
- **Image**: PNG file with transparent background
- **Width/Height**: Display dimensions in pixels
- **Initial X/Y**: Starting position as percentage (0-100%)
- **Scatter Distance**: How far to scatter on load (0-500px)
- **Rotation Angle**: Initial rotation (-180 to 180 degrees)
- **Display Order**: Order of items (drag to reorder in admin)
- **Active Status**: Show/hide item

## Usage Tips

### For Best Results:
1. Use high-quality PNG images with transparent backgrounds
2. Keep file sizes optimized for fast loading
3. Start with 5-10 furniture items
4. Position items strategically for visual appeal
5. Test on mobile devices for touch interaction
6. Use moderate scatter distances (100-300px)
7. Set appropriate item dimensions for screen size

### Animation Recommendations:
- **Scatter Duration**: 2000ms (2 seconds) works well
- **Easing**: 'ease-out' for natural movement
- **Grid Size**: 20px for subtle snapping
- **Scatter Distance**: 200px for noticeable but not excessive movement

## Troubleshooting

### Items Not Appearing:
- Check if animation is enabled in settings
- Verify items are marked as active
- Check browser console for JavaScript errors
- Ensure PNG images are accessible

### Animation Not Working:
- Clear browser cache
- Check if JavaScript file is loaded
- Verify database connection
- Check browser console for errors

### Drag Not Working:
- Ensure "Allow Drag" is enabled in settings
- Check if items have proper z-index
- Test on different browsers
- Verify touch events on mobile

### Performance Issues:
- Reduce number of active items
- Optimize PNG file sizes
- Reduce scatter duration
- Disable snap-to-grid if not needed

## Browser Compatibility
- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## Security Notes
- Only admins can access furniture management
- File uploads are validated and secured
- PNG files are stored in static directory
- Database queries use parameterized statements

## Future Enhancements
- [ ] Collision detection between items
- [ ] Save user arrangements to database
- [ ] Multiple layout presets
- [ ] 3D rotation effects
- [ ] Sound effects on interactions
- [ ] Social sharing of arrangements
- [ ] AI-powered layout suggestions

## Support
For issues or questions, check:
1. Browser console for JavaScript errors
2. Flask logs for server errors
3. Database logs for query issues
4. Network tab for asset loading problems