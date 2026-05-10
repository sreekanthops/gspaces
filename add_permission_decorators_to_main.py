#!/usr/bin/env python3
"""
Script to add permission checks to admin routes in main.py
This ensures that:
- Delete routes check can_delete permission
- Edit/Update routes check can_write permission
- View routes only check is_admin
"""

import re

# Read the file
with open('main.py', 'r') as f:
    lines = f.readlines()

# Helper function to check if user has delete permission
delete_check = """    # Check delete permission
    conn_check = connect_to_db()
    if conn_check:
        try:
            cur_check = conn_check.cursor(cursor_factory=RealDictCursor)
            cur_check.execute("SELECT can_delete FROM users WHERE id = %s", (current_user.id,))
            user_perms = cur_check.fetchone()
            cur_check.close()
            conn_check.close()
            if not user_perms or not user_perms.get('can_delete', False):
                flash("Delete permission required. Only Full Admins can perform this action.", "danger")
                return redirect(url_for('admin_orders'))
        except:
            if conn_check:
                conn_check.close()
            flash("Permission check failed", "danger")
            return redirect(url_for('admin_orders'))
"""

# Helper function to check if user has write permission
write_check = """    # Check write permission
    conn_check = connect_to_db()
    if conn_check:
        try:
            cur_check = conn_check.cursor(cursor_factory=RealDictCursor)
            cur_check.execute("SELECT can_write, can_delete FROM users WHERE id = %s", (current_user.id,))
            user_perms = cur_check.fetchone()
            cur_check.close()
            conn_check.close()
            if not user_perms or not (user_perms.get('can_write', False) or user_perms.get('can_delete', False)):
                flash("Write permission required. You only have Read access.", "warning")
                return redirect(url_for('admin_orders'))
        except:
            if conn_check:
                conn_check.close()
            flash("Permission check failed", "danger")
            return redirect(url_for('admin_orders'))
"""

# Routes that need delete permission check
delete_routes = [
    '/admin/reviews/<int:review_id>/delete',
    '/admin/coupons/delete/<int:coupon_id>',
    '/admin/customers/<int:customer_id>/delete',
    '/admin/inquiries/<int:inquiry_id>/delete',
    '/admin/carousel/image/<int:image_id>/delete',
    '/admin/animated-furniture/item/<int:item_id>/delete',
    '/delete_product/<int:product_id>',
    '/delete_main_image/<int:product_id>',
    '/delete_sub_image/<int:sub_image_id>'
]

# Routes that need write permission check (edit/update operations)
write_routes = [
    '/admin/orders/update_status/<int:order_id>',
    '/admin/coupons/edit/<int:coupon_id>',
    '/admin/coupons/toggle/<int:coupon_id>',
    '/admin/homepage-banner/update',
    '/admin/carousel/settings/update',
    '/admin/carousel/image/<int:image_id>/update',
    '/admin/animated-furniture/settings/update',
    '/admin/animated-furniture/item/<int:item_id>/update',
    '/admin/animated-furniture/item/<int:item_id>/toggle'
]

output = []
i = 0
while i < len(lines):
    line = lines[i]
    output.append(line)
    
    # Check if this is a route definition
    if '@app.route(' in line:
        route_line = line.strip()
        
        # Check if it's a delete route
        is_delete_route = any(route in route_line for route in delete_routes)
        
        # Check if it's a write route
        is_write_route = any(route in route_line for route in write_routes)
        
        # Look ahead to find the function definition and admin check
        j = i + 1
        while j < len(lines) and not lines[j].strip().startswith('def '):
            output.append(lines[j])
            j += 1
        
        if j < len(lines):
            # Found function definition
            output.append(lines[j])  # def function_name():
            j += 1
            
            # Add docstring if present
            if j < len(lines) and '"""' in lines[j]:
                output.append(lines[j])
                j += 1
                while j < len(lines) and '"""' not in lines[j]:
                    output.append(lines[j])
                    j += 1
                if j < len(lines):
                    output.append(lines[j])
                    j += 1
            
            # Check for existing admin check
            if j < len(lines) and 'if not current_user.is_admin:' in lines[j]:
                output.append(lines[j])  # Keep the is_admin check
                j += 1
                # Skip the flash and redirect lines
                while j < len(lines) and ('flash(' in lines[j] or 'return redirect' in lines[j]):
                    output.append(lines[j])
                    j += 1
                
                # Add permission check after admin check
                if is_delete_route:
                    output.append('\n')
                    output.append(delete_check)
                elif is_write_route:
                    output.append('\n')
                    output.append(write_check)
            
            # Continue with rest of function
            while j < len(lines):
                output.append(lines[j])
                j += 1
                if j < len(lines) and lines[j].strip() and not lines[j].startswith(' ') and not lines[j].startswith('\t'):
                    break
            
            i = j - 1
    
    i += 1

# Write back
with open('main.py', 'w') as f:
    f.writelines(output)

print("✅ Added permission checks to admin routes in main.py")
print(f"   - Delete routes now check can_delete permission")
print(f"   - Edit/Update routes now check can_write permission")
print("\n⚠️  Note: This is a complex operation. Please review the changes carefully!")
print("   Run: git diff main.py")

# Made with Bob
