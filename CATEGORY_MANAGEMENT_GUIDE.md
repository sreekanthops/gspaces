# Category Management System - Deployment Guide

## Overview
This system allows admins to dynamically manage product categories without code changes. Categories can be added, edited, reordered, and toggled active/inactive through an admin interface.

## New Categories
The following categories will be added:
1. **Ergonomic** (existing)
2. **Minimalist** (existing)
3. **Executive** (existing)
4. **Greenery** (new)
5. **Couple Studio** (new)
6. **Basic Storage** (new)
7. **Elegant** (new)
8. **Luxury Studio** (new)

## Files Created/Modified

### New Files:
1. `create_categories_table.sql` - Database schema and migration
2. `category_routes.py` - Flask routes for category management
3. `templates/admin_categories.html` - Admin UI for managing categories
4. `CATEGORY_MANAGEMENT_GUIDE.md` - This file

### Files to Modify:
1. `main.py` - Import and register category routes
2. `templates/navbar.html` - Update to use dynamic categories with "More" dropdown
3. `templates/add_product.html` - Use dynamic category dropdown
4. `templates/edit_product.html` - Use dynamic category dropdown

## Deployment Steps

### Step 1: Database Migration
```bash
# Connect to PostgreSQL
psql -U postgres -d gspaces

# Run the migration script
\i create_categories_table.sql

# Verify categories were created
SELECT * FROM categories ORDER BY display_order;
```

### Step 2: Update main.py
Add these imports at the top:
```python
from category_routes import register_category_routes
```

After creating the Flask app, register the routes:
```python
# Register category management routes
register_category_routes(app)
```

### Step 3: Update Product Forms
The product add/edit forms need to fetch categories dynamically from the database instead of hardcoded values.

In routes that render add_product.html or edit_product.html:
```python
# Fetch active categories
cur.execute("""
    SELECT id, name FROM categories 
    WHERE is_active = TRUE 
    ORDER BY display_order
""")
categories = cur.fetchall()

return render_template('add_product.html', categories=categories)
```

### Step 4: Update Navigation
The navbar should display categories dynamically with a "More" dropdown for overflow.

### Step 5: Restart Application
```bash
# If using systemd
sudo systemctl restart gspaces

# If using screen/tmux
# Stop the current process and restart
python main.py
```

## Features

### Admin Interface (`/admin/categories`)
- **Add Category**: Create new categories with custom names and slugs
- **Edit Category**: Modify existing category details
- **Toggle Active/Inactive**: Show/hide categories from users
- **Drag to Reorder**: Change display order by dragging
- **Delete Category**: Remove unused categories (prevents deletion if products exist)
- **Statistics**: View total, active, and inactive category counts

### Category Properties
- **Name**: Display name (e.g., "Luxury Studio")
- **Slug**: URL-friendly identifier (e.g., "luxury-studio")
- **Display Order**: Controls navigation menu order
- **Active Status**: Whether visible to users
- **Timestamps**: Created and updated dates

### API Endpoint
`GET /api/categories` - Returns all active categories as JSON

## Database Schema

```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Migration Strategy

### Existing Products
- Products keep their current category text in the `category` column
- New `category_id` column links to the categories table
- Migration script automatically maps existing categories to new IDs
- No data loss - all existing products are preserved

### Backward Compatibility
- Old `category` column remains for reference
- New code uses `category_id` for lookups
- Can safely remove `category` column after verifying migration

## Navigation "More" Dropdown

When there are more than 6 categories, the navbar will show:
- First 5 categories as regular menu items
- "More" dropdown containing remaining categories

This prevents navigation overflow on smaller screens.

## Security

- All category management routes require admin authentication
- SQL injection protection via parameterized queries
- CSRF protection via Flask forms
- Input validation on all fields

## Testing Checklist

- [ ] Database migration runs successfully
- [ ] Categories table created with all 8 categories
- [ ] Admin can access `/admin/categories`
- [ ] Can add new category
- [ ] Can edit existing category
- [ ] Can toggle category active/inactive
- [ ] Can reorder categories by dragging
- [ ] Cannot delete category with products
- [ ] Product forms show dynamic categories
- [ ] Navigation displays categories correctly
- [ ] "More" dropdown appears when >6 categories
- [ ] Existing products still display correctly
- [ ] API endpoint returns active categories

## Troubleshooting

### Categories not showing in admin panel
- Check database connection in `category_routes.py`
- Verify `categories` table exists: `\dt categories`
- Check Flask logs for errors

### Products not showing categories
- Verify `category_id` column exists in products table
- Run migration script to populate `category_id`
- Check that categories are marked as active

### "More" dropdown not appearing
- Check navbar template is updated
- Verify JavaScript is loading
- Check browser console for errors

## Future Enhancements

1. **Category Images**: Add thumbnail images for each category
2. **Category Descriptions**: SEO-friendly descriptions
3. **Subcategories**: Hierarchical category structure
4. **Category Analytics**: Track views and conversions per category
5. **Bulk Operations**: Enable/disable multiple categories at once
6. **Category Filters**: Advanced filtering in product listings

## Support

For issues or questions:
1. Check Flask application logs
2. Verify database connection
3. Review this guide
4. Check PostgreSQL logs: `/var/log/postgresql/`

## Rollback Plan

If issues occur, rollback steps:
```sql
-- Remove category_id from products
ALTER TABLE products DROP COLUMN IF EXISTS category_id;

-- Drop categories table
DROP TABLE IF EXISTS categories;

-- Application will fall back to using text category column
```

## Summary

This category management system provides:
- ✅ Dynamic category management
- ✅ Admin-friendly interface
- ✅ Drag-and-drop reordering
- ✅ Active/inactive toggle
- ✅ Safe deletion with product checks
- ✅ Backward compatible migration
- ✅ Responsive navigation with "More" dropdown
- ✅ API endpoint for integrations

All existing products are preserved and automatically migrated to the new system.