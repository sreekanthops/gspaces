# Default Items Management System - Complete Guide

## Overview
This system allows admins to manage all default items and prices from a centralized admin panel. Items can be added, edited, deleted, and have custom icons uploaded. These items automatically sync to the edit lead page where they can be selected for quotations.

## Features

### ✅ Admin Panel Features
- **Add New Items**: Create new items with custom names, slugs, prices, and icons
- **Edit Items**: Update existing items including prices, descriptions, and icons
- **Delete Items**: Remove items that are no longer needed
- **Icon Upload**: Upload custom icon images (PNG, JPG, SVG) or use emoji icons
- **Active/Inactive Status**: Control which items are available for selection
- **Display Order**: Set the order in which items appear in the UI
- **Bulk Price Update**: Update all default prices at once

### ✅ Edit Lead Page Features
- **Auto-Sync**: Items automatically sync from default_items table
- **Default Prices**: Prices auto-fill from default items
- **Dropdown Selection**: Pick items from available default items (future enhancement)
- **Custom Icons**: Display custom uploaded icons or emoji fallbacks

## Database Schema

### default_items Table
```sql
CREATE TABLE default_items (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL UNIQUE,
    item_slug VARCHAR(100) NOT NULL UNIQUE,
    icon_emoji VARCHAR(10) DEFAULT '📦',
    icon_image VARCHAR(500),  -- Path to uploaded icon
    default_price DECIMAL(10,2) DEFAULT 0,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Installation

### Step 1: Run SQL Migration
```bash
sudo -u postgres psql gspaces < create_enhanced_default_items.sql
```

### Step 2: Deploy Files
```bash
sudo bash deploy_default_items_system.sh
```

Or manually:
```bash
# Backup existing files
cp /var/www/gspaces/leads_routes.py /var/www/gspaces/leads_routes.py.backup
cp /var/www/gspaces/templates/admin_default_prices.html /var/www/gspaces/templates/admin_default_prices.html.backup

# Copy new files
cp leads_routes.py /var/www/gspaces/
cp templates/admin_default_prices.html /var/www/gspaces/templates/

# Create icons directory
mkdir -p /var/www/gspaces/static/img/icons
chown www-data:www-data /var/www/gspaces/static/img/icons

# Restart services
sudo systemctl restart gspaces
sudo systemctl restart nginx
```

## Usage Guide

### For Admins

#### Adding a New Item
1. Navigate to **Admin Panel** → **Manage Default Items & Prices**
2. Click **"Add New Item"** button
3. Fill in the form:
   - **Item Name**: Display name (e.g., "Desk Lamp")
   - **Item Slug**: URL-friendly identifier (e.g., "desk_lamp")
   - **Emoji Icon**: Fallback emoji (e.g., "💡")
   - **Icon Image**: Upload custom icon (optional)
   - **Default Price**: Price in ₹
   - **Display Order**: Order in UI (0 = first)
   - **Description**: Brief description
   - **Active**: Check to make available
4. Click **"Add Item"**

#### Editing an Item
1. Find the item in the list
2. Click the **pencil icon** (✏️) on the item card
3. Update the fields as needed
4. Upload a new icon if desired
5. Click **"Update Item"**

#### Deleting an Item
1. Find the item in the list
2. Click the **trash icon** (🗑️) on the item card
3. Confirm deletion in the modal
4. Click **"Delete Item"**

⚠️ **Warning**: Deleting an item is permanent and cannot be undone!

#### Updating All Prices
1. Edit the price fields directly on the item cards
2. Scroll to the bottom
3. Click **"Update All Default Prices"**
4. All prices will be updated at once

### For Lead Management

#### Using Items in Quotations
1. Navigate to **Edit Lead** page
2. Items from default_items table automatically appear
3. Default prices are pre-filled
4. Check items to include in the quotation
5. Adjust quantities and prices as needed
6. Items sync automatically from the admin panel

## API Endpoints

### GET /admin/default-prices
Display the default items management page

### POST /admin/default-prices/update
Update all default prices
- **Parameters**: `price_{item_slug}` for each item

### POST /admin/default-items/add
Add a new default item
- **Parameters**:
  - `item_name` (required)
  - `item_slug` (required)
  - `icon_emoji` (optional)
  - `icon_image` (file, optional)
  - `default_price` (required)
  - `description` (optional)
  - `display_order` (optional)
  - `is_active` (checkbox)

### POST /admin/default-items/update
Update an existing item
- **Parameters**: Same as add, plus `item_id`

### POST /admin/default-items/delete
Delete an item
- **Parameters**: `item_id`

## File Structure

```
/var/www/gspaces/
├── leads_routes.py                    # Updated with CRUD endpoints
├── templates/
│   └── admin_default_prices.html      # Enhanced admin page
├── static/
│   └── img/
│       └── icons/                     # Custom icon uploads
└── create_enhanced_default_items.sql  # Database migration
```

## Icon Guidelines

### Supported Formats
- PNG (recommended)
- JPG/JPEG
- SVG
- GIF

### Recommended Specifications
- Size: 50x50 to 100x100 pixels
- Format: PNG with transparency
- File size: < 2MB
- Background: Transparent

### Emoji Fallback
If no custom icon is uploaded, the system uses the emoji icon specified in the `icon_emoji` field.

## Troubleshooting

### Icons Not Displaying
1. Check file permissions: `ls -la /var/www/gspaces/static/img/icons/`
2. Ensure directory is owned by www-data: `sudo chown -R www-data:www-data /var/www/gspaces/static/img/icons/`
3. Check file path in database matches actual file location

### Items Not Appearing in Edit Lead
1. Verify item is marked as **Active** in admin panel
2. Check database: `SELECT * FROM default_items WHERE is_active = TRUE;`
3. Clear browser cache and reload page

### Price Updates Not Saving
1. Check database connection
2. Verify user has admin privileges
3. Check browser console for JavaScript errors
4. Review server logs: `sudo journalctl -u gspaces -n 50`

### Upload Errors
1. Check directory permissions: `sudo chmod 755 /var/www/gspaces/static/img/icons/`
2. Verify file size is under 2MB
3. Ensure file format is supported
4. Check disk space: `df -h`

## Best Practices

### Item Naming
- Use clear, descriptive names
- Keep slugs lowercase with underscores
- Avoid special characters in slugs

### Pricing
- Set realistic default prices
- Update prices regularly
- Consider market rates

### Icons
- Use consistent icon style
- Optimize images before upload
- Use transparent backgrounds
- Test icons on different backgrounds

### Organization
- Use display_order to group related items
- Mark unused items as inactive instead of deleting
- Add detailed descriptions for clarity

## Future Enhancements

### Planned Features
- [ ] Dropdown selector in edit lead page to add items dynamically
- [ ] Bulk import/export of items
- [ ] Item categories and filtering
- [ ] Price history tracking
- [ ] Item usage analytics
- [ ] Duplicate item detection
- [ ] Icon library/gallery
- [ ] Multi-language support

## Support

For issues or questions:
1. Check this guide first
2. Review server logs
3. Test in a staging environment
4. Contact system administrator

## Changelog

### Version 1.0 (2026-05-03)
- Initial release
- Enhanced default_items table with icon support
- Full CRUD operations for items
- Icon upload functionality
- Active/inactive status
- Display order management
- Auto-sync to edit lead page

---

**Made with Bob** 🤖