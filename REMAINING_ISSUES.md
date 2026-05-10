# Remaining Issues to Fix

## 1. Visitor Tracking Database Error ✅ SQL Fix Provided
**Error**: `record "new" has no field "updated_at"`

**Solution**: Run the SQL fix:
```bash
psql -U postgres -d gspaces -f fix_visitor_tracking_trigger.sql
```

This will drop the problematic triggers that are trying to update a non-existent column.

## 2. Sidebar Menu Items Removed ✅ Fixed
**Issue**: "Visitors" and "System Health" menu items showing but routes don't exist

**Solution**: Removed these menu items from `templates/admin_sidebar.html`

## 3. Admin Panel Layout Issues ⚠️ Needs Manual Review
**Issue**: 
- Containers coming too close to sidebar
- Sidebar not stable
- Layout not consistent across admin sections

**Possible Causes**:
- Missing or inconsistent Bootstrap grid classes
- Different templates using different layouts
- CSS conflicts between templates

**Recommended Fix**:
Review and standardize the layout across all admin templates. Most admin pages should follow this structure:

```html
<div class="container-fluid" style="margin-top: 76px;">
    <div class="row g-0">
        <!-- Sidebar (2 columns) -->
        <div class="col-md-2">
            {% set active_page = 'page_name' %}
            {% include 'admin_sidebar.html' %}
        </div>
        
        <!-- Main Content (10 columns) -->
        <div class="col-md-10" style="background: #f8f9fa; min-height: calc(100vh - 76px); padding: 24px;">
            <!-- Your content here -->
        </div>
    </div>
</div>
```

**Templates to Check**:
- templates/admin_orders.html
- templates/admin_inquiries.html
- templates/admin_leads_simple.html
- templates/admin_default_prices.html
- templates/admin_coupons.html
- templates/admin_referral_coupons.html
- templates/admin_deals.html
- templates/admin_reviews.html
- templates/admin_gst_settings.html
- templates/admin_users.html
- templates/admin_blogs.html
- templates/admin_homepage_carousel.html
- templates/admin_animated_furniture.html

## 4. Missing Footer in Admin Pages ⚠️ Design Decision
**Issue**: Footer not showing in admin panel sections

**Options**:
1. **Remove footer from admin pages** (Recommended) - Admin panels typically don't have footers
2. **Add footer to all admin pages** - Include `{% include 'footer.html' %}` before `</body>` tag

## Summary of Completed Work

### ✅ Admin Permission System
- Granular permissions (Read, Write, Full)
- Database schema with permission columns
- Permission management UI
- Revoke button for admin users

### ✅ Admin Access Fixed
- 20 routes updated to use `is_admin` flag
- All pages accessible to admin users
- Deals & Promotions split into separate items

### ✅ Default Prices Fixed
- Edit button working
- Delete button working
- JavaScript functions properly defined

### ✅ Users Management
- Permission badges showing
- Grant access form with dropdown
- Revoke button added

## Next Steps

1. **Immediate**: Run `fix_visitor_tracking_trigger.sql` to stop database errors
2. **Layout**: Review and standardize admin template layouts
3. **Footer**: Decide whether to add or remove from admin pages
4. **Testing**: Test all admin pages after layout fixes

## Files Modified in This Session
- update_admin_permissions_granular.sql
- admin_users_routes.py
- templates/admin_users.html
- templates/admin_sidebar.html
- templates/admin_default_prices.html
- main.py (20 routes updated)
- fix_visitor_tracking_trigger.sql
- Multiple documentation files