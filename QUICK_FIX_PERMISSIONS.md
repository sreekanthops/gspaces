# Quick Fix for Permission Issue

## Problem
User with "Write Access" can still delete items because the routes in `main.py` only check `is_admin` flag, not the granular permissions (`can_write`, `can_delete`).

## Quick Solution

Add these helper functions to `main.py` after the User class definition (around line 250):

```python
def check_delete_permission():
    """Check if current user has delete permission"""
    if not current_user.is_authenticated or not current_user.is_admin:
        return False
    
    conn = connect_to_db()
    if not conn:
        return False
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT can_delete FROM users WHERE id = %s", (current_user.id,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        return user and user.get('can_delete', False)
    except:
        if conn:
            conn.close()
        return False

def check_write_permission():
    """Check if current user has write permission"""
    if not current_user.is_authenticated or not current_user.is_admin:
        return False
    
    conn = connect_to_db()
    if not conn:
        return False
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT can_write, can_delete FROM users WHERE id = %s", (current_user.id,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        return user and (user.get('can_write', False) or user.get('can_delete', False))
    except:
        if conn:
            conn.close()
        return False
```

## Then Update Delete Routes

For each delete route, add this check after the `is_admin` check:

### Example - Review Delete Route (line 2288):

**BEFORE:**
```python
@app.route('/admin/reviews/<int:review_id>/delete', methods=['POST'])
@login_required
def admin_delete_review(review_id):
    """Delete a review"""
    if current_user.email not in ADMIN_EMAILS:
        flash("Access denied. Admin privileges required.", "danger")
        return redirect(url_for('index'))
```

**AFTER:**
```python
@app.route('/admin/reviews/<int:review_id>/delete', methods=['POST'])
@login_required
def admin_delete_review(review_id):
    """Delete a review"""
    if not current_user.is_admin:
        flash("Access denied. Admin privileges required.", "danger")
        return redirect(url_for('index'))
    
    if not check_delete_permission():
        flash("Delete permission required. Only Full Admins can perform this action.", "danger")
        return redirect(url_for('admin_reviews'))
```

## Routes That Need Delete Permission Check

Add `if not check_delete_permission():` check to these routes:

1. `/admin/reviews/<int:review_id>/delete` (line 2288)
2. `/admin/coupons/delete/<int:coupon_id>` (line 3298)
3. `/admin/customers/<int:customer_id>/delete` (line 3445)
4. `/admin/inquiries/<int:inquiry_id>/delete` (line 4520)
5. `/admin/carousel/image/<int:image_id>/delete` (line 4866)
6. `/admin/animated-furniture/item/<int:item_id>/delete` (line 5224)
7. `/delete_product/<int:product_id>` (line 1774)
8. `/delete_main_image/<int:product_id>` (line 1798)
9. `/delete_sub_image/<int:sub_image_id>` (line 1819)

## Routes That Need Write Permission Check

Add `if not check_write_permission():` check to these routes:

1. `/admin/orders/update_status/<int:order_id>` (line 3099)
2. `/admin/coupons/edit/<int:coupon_id>` (line 2867)
3. `/admin/coupons/toggle/<int:coupon_id>` (line 2845)
4. `/admin/coupons/add` (line 2785)
5. `/admin/homepage-banner/update` (line 4580)
6. `/admin/carousel/settings/update` (line 4696)
7. `/admin/carousel/image/add` (line 4735)
8. `/admin/carousel/image/<int:image_id>/update` (line 4827)
9. `/admin/animated-furniture/settings/update` (line 4997)
10. `/admin/animated-furniture/item/add` (line 5049)
11. `/admin/animated-furniture/item/<int:item_id>/update` (line 5150)
12. `/admin/animated-furniture/item/<int:item_id>/toggle` (line 5252)

## Automated Script

I've created `update_admin_checks.py` which will:
1. Replace all `if current_user.email not in ADMIN_EMAILS:` with `if not current_user.is_admin:`

You still need to manually add the permission checks to delete and write routes.

## Testing

After making changes:

1. **Test Read Only User:**
   - Should see admin panel
   - Should NOT see edit/delete buttons
   - Should get error if trying to access edit/delete URLs directly

2. **Test Write Access User:**
   - Should see admin panel
   - Should see edit buttons
   - Should NOT see delete buttons
   - Should get error if trying to access delete URLs directly

3. **Test Full Admin:**
   - Should have complete access to everything

## Verification Query

Check user's permissions:
```sql
SELECT id, name, email, is_admin, can_read, can_write, can_delete
FROM users 
WHERE email = 'user@example.com';
```

Expected for Write Access:
- `is_admin`: true
- `can_read`: true
- `can_write`: true
- `can_delete`: false