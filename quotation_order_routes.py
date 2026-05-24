"""
Quotation to Order Routes
Handles creating orders from quotations with full data integration
"""

from flask import Blueprint, request, jsonify, render_template
from flask_login import login_required, current_user
from psycopg2.extras import RealDictCursor
from datetime import datetime
import json

# Create blueprint
quotation_order_bp = Blueprint('quotation_order', __name__)

# Database connection function (will be set from main.py)
_db_connection_func = None

def set_db_connection_func(func):
    """Set the database connection function"""
    global _db_connection_func
    _db_connection_func = func

def get_db_connection():
    """Get database connection"""
    if _db_connection_func is None:
        raise RuntimeError("Database connection function not set")
    return _db_connection_func()


# Icon mapping for standard items (using actual filenames that exist)
ITEM_ICON_MAP = {
    'table': 'img/icons/icon_table_20260503_163612_desk.png',
    'chair': 'img/icons/icon_lounge_chairs_20260516_182534_lounge_chairs.png',
    'plants': 'img/icons/icon_buddha_statue_20260516_183321_buddha.png',
    'mini_plants': 'img/icons/icon_buddha_statue_20260516_183321_buddha.png',
    'big_plants': 'img/icons/icon_buddha_statue_20260516_183321_buddha.png',
    'lighting': 'img/icons/icon_track_light_20260511_205430_track_light.png',
    'storage': 'img/icons/icon_wall_racks_20260503_170008_Screenshot_2026-05-03_at_10.29.23_PM.png',
    'accessories': 'img/icons/icon_pen_holder_20260503_170322_Screenshot_2026-05-03_at_10.33.03_PM.png',
    'frames': 'img/icons/icon_wall_mirror_20260512_184840_mirror.png',
    'desk_lamp': 'img/icons/icon_desk_lamp_20260503_170218_table-lamp.png',
    'pen_holder': 'img/icons/icon_pen_holder_20260503_170322_Screenshot_2026-05-03_at_10.33.03_PM.png',
    'wall_racks': 'img/icons/icon_wall_racks_20260503_170008_Screenshot_2026-05-03_at_10.29.23_PM.png',
    'desk_mat': 'img/icons/icon_desk_mat_20260503_170116_Screenshot_2026-05-03_at_10.31.05_PM.png',
    'dustbin': 'img/icons/icon_socket_20260503_164948_extension.png',
    'floor_mat': 'img/icons/icon_floor_mat_20260503_170630_Screenshot_2026-05-03_at_10.36.11_PM.png',
    'keyboard': 'img/icons/icon_laptop_stand_20260503_170522_Screenshot_2026-05-03_at_10.35.00_PM.png',
    'mouse': 'img/icons/icon_laptop_stand_20260503_170522_Screenshot_2026-05-03_at_10.35.00_PM.png',
    'curtains': 'img/icons/icon_curtains_20260514_090008_curtains.png',
    'monitor': 'img/icons/icon_laptop_stand_20260503_170522_Screenshot_2026-05-03_at_10.35.00_PM.png',
    'laptop_stand': 'img/icons/icon_laptop_stand_20260503_170522_Screenshot_2026-05-03_at_10.35.00_PM.png',
    'neon': 'img/icons/icon_neon_20260514_090322_neon.png',
    'track_light': 'img/icons/icon_track_light_20260511_205430_track_light.png',
    'floor_lamp': 'img/icons/icon_floor_lamp_20260511_204740_floor_lamp.png',
}

def extract_items_from_quotation(lead_designs):
    """Extract all items from quotation designs - supports both JSONB arrays and old schema"""
    items = []
    
    print(f"DEBUG: Extracting items from {len(lead_designs)} designs")
    
    for design_idx, design in enumerate(lead_designs):
        print(f"DEBUG: Processing design {design_idx + 1}")
        print(f"DEBUG: Design keys: {design.keys()}")
        
        # Try both plural and singular forms, and check what's actually in the design
        item_categories = [
            ('tables', 'table'),
            ('chairs', 'chair'),
            ('plants', 'plant'),
            ('lighting', 'light'),
            ('storage', 'storage'),
            ('accessories', 'accessory'),
            ('custom_items', 'custom_item')
        ]
        
        for category_plural, category_singular in item_categories:
            # Try plural first, then singular
            category_items = design.get(category_plural) or design.get(category_singular)
            print(f"DEBUG: Category '{category_plural}/{category_singular}' type: {type(category_items)}, value: {category_items}")
            
            if category_items:
                try:
                    # Parse if string, otherwise use as-is
                    if isinstance(category_items, str):
                        category_items = json.loads(category_items)
                        print(f"DEBUG: Parsed {category_plural} from string: {category_items}")
                    
                    # Process each item in the category
                    if isinstance(category_items, list):
                        print(f"DEBUG: Found {len(category_items)} items in {category_plural}")
                        for item in category_items:
                            if isinstance(item, dict) and item.get('price', 0) > 0:
                                extracted_item = {
                                    'name': item.get('name') or item.get('details', category_plural.title()),
                                    'quantity': int(item.get('quantity', 1)),
                                    'price': float(item.get('price', 0)),
                                    'image': item.get('image') or item.get('icon')  # Include image/icon if available
                                }
                                items.append(extracted_item)
                                print(f"DEBUG: Added item: {extracted_item}")
                except Exception as e:
                    print(f"ERROR extracting {category_plural}: {e}")
                    import traceback
                    traceback.print_exc()
        
        # Also extract from old schema fields (for backward compatibility)
        # Don't use "if not items" - we want to extract from BOTH if available
        items_before_fallback = len(items)
        
        # Table
        if design.get('has_table') and design.get('table_price', 0) > 0:
            table_details = design.get('table_details', 'Office Table')
            # Extract simple name from details (first part before description)
            table_name = table_details.split('\n')[0] if '\n' in table_details else table_details
            items.append({
                'name': table_name,
                'quantity': design.get('table_quantity', 1),
                'price': float(design.get('table_price', 0)),
                'image': ITEM_ICON_MAP.get('table')
            })
        
        # Chair
        if design.get('has_chair') and design.get('chair_price', 0) > 0:
            chair_details = design.get('chair_details', 'Office Chair')
            chair_name = chair_details.split('\n')[0] if '\n' in chair_details else chair_details
            items.append({
                'name': chair_name,
                'quantity': design.get('chair_quantity', 1),
                'price': float(design.get('chair_price', 0)),
                'image': ITEM_ICON_MAP.get('chair')
            })
        
        # Plants
        if design.get('has_plants') and design.get('plants_price', 0) > 0:
            plants_details = design.get('plants_details', 'Plants')
            plants_name = plants_details.split('\n')[0] if '\n' in plants_details else plants_details
            items.append({
                'name': plants_name,
                'quantity': design.get('plants_quantity', 1),
                'price': float(design.get('plants_price', 0)),
                'image': ITEM_ICON_MAP.get('plants')
            })
        
        # Lighting
        if design.get('has_lighting') and design.get('lighting_price', 0) > 0:
            lighting_details = design.get('lighting_details', 'Lighting')
            lighting_name = lighting_details.split('\n')[0] if '\n' in lighting_details else lighting_details
            items.append({
                'name': lighting_name,
                'quantity': design.get('lighting_quantity', 1),
                'price': float(design.get('lighting_price', 0)),
                'image': ITEM_ICON_MAP.get('lighting')
            })
        
        # Storage
        if design.get('has_storage') and design.get('storage_price', 0) > 0:
            storage_details = design.get('storage_details', 'Storage')
            storage_name = storage_details.split('\n')[0] if '\n' in storage_details else storage_details
            items.append({
                'name': storage_name,
                'quantity': design.get('storage_quantity', 1),
                'price': float(design.get('storage_price', 0)),
                'image': ITEM_ICON_MAP.get('storage')
            })
        
        # Accessories
        if design.get('has_accessories') and design.get('accessories_price', 0) > 0:
            accessories_details = design.get('accessories_details', 'Accessories')
            accessories_name = accessories_details.split('\n')[0] if '\n' in accessories_details else accessories_details
            items.append({
                'name': accessories_name,
                'quantity': design.get('accessories_quantity', 1),
                'price': float(design.get('accessories_price', 0)),
                'image': ITEM_ICON_MAP.get('accessories')
            })
        
        # Additional specific items
        additional_items = [
            'mini_plants', 'big_plants', 'frames', 'wall_racks', 'desk_mat', 'dustbin',
            'floor_mat', 'keyboard', 'mouse', 'paint', 'wardrobes', 'deskmat', 'carpet',
            'curtains', 'wall_art', 'desk_organizer', 'monitor_stand', 'cable_management',
            'footrest', 'monitor', 'laptop_stand', 'headphone_stand', 'whiteboard',
            'bookshelf', 'trash_bin', 'desk_lamp', 'pen_holder', 'laptop_holder',
            'profile_lighting', 'multi_socket'
        ]
        
        for item_type in additional_items:
            has_key = f'has_{item_type}'
            price_key = f'{item_type}_price'
            details_key = f'{item_type}_details'
            quantity_key = f'{item_type}_quantity'
            
            if design.get(has_key) and design.get(price_key, 0) > 0:
                item_details = design.get(details_key, item_type.replace('_', ' ').title())
                # Extract simple name (first line or before newline)
                item_name = item_details.split('\n')[0] if '\n' in item_details else item_details
                items.append({
                    'name': item_name,
                    'quantity': design.get(quantity_key, 1),
                    'price': float(design.get(price_key, 0)),
                    'image': ITEM_ICON_MAP.get(item_type)  # Use icon from map if available
                })
        
        print(f"DEBUG: Extracted {len(items) - items_before_fallback} items from old schema fields")
    
    print(f"DEBUG: Total items extracted: {len(items)}")
    print(f"DEBUG: Items list: {items}")
    return items


@quotation_order_bp.route('/quotation/<share_token>/create-order', methods=['POST'])
@login_required
def create_order_from_quotation(share_token):
    """Create order from quotation with all details pre-filled"""
    
    # Check admin privileges
    if not current_user.is_admin:
        return jsonify({
            'success': False,
            'message': 'Access denied. Admin privileges required.'
        }), 403
    
    try:
        # Get form data
        data = request.get_json() if request.is_json else request.form
        
        # Get discount and price overrides
        discount_percentage = float(data.get('discount_percentage', 0))
        final_price_override = data.get('final_price_override')
        customer_type = data.get('customer_type', 'quotation_order')
        admin_notes = data.get('admin_notes', '').strip()
        
        # Connect to database
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Database connection failed'
            }), 500
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get quotation details
            cur.execute("""
                SELECT * FROM leads WHERE share_token = %s
            """, (share_token,))
            
            lead = cur.fetchone()
            
            if not lead:
                return jsonify({
                    'success': False,
                    'message': 'Quotation not found'
                }), 404
            
            # Check if order already exists - if so, update it instead of creating new
            existing_order_id = None
            if lead.get('order_created') and lead.get('order_id'):
                existing_order_id = lead.get('order_id')
            
            # Get quotation designs
            cur.execute("""
                SELECT * FROM lead_designs WHERE lead_id = %s ORDER BY design_order
            """, (lead['id'],))
            
            lead_designs = cur.fetchall()
            
            if not lead_designs:
                return jsonify({
                    'success': False,
                    'message': 'No designs found in quotation'
                }), 404
            
            # Extract items from quotation
            items = extract_items_from_quotation(lead_designs)
            
            # Calculate pricing - ensure all values are Decimal for consistency
            from decimal import Decimal
            original_price = sum(Decimal(str(design.get('subtotal', 0) or design.get('final_price', 0) or design.get('price', 0))) for design in lead_designs)
            
            if final_price_override:
                final_price = Decimal(str(final_price_override))
                discount_amount = original_price - final_price
                if original_price > 0:
                    discount_percentage = float((discount_amount / original_price) * 100)
            else:
                discount_percentage = float(discount_percentage)
                discount_amount = (original_price * Decimal(str(discount_percentage))) / Decimal('100')
                final_price = original_price - discount_amount
            
            # Get primary design details
            primary_design = lead_designs[0]
            design_name = primary_design.get('design_name', lead.get('project_name', 'Custom Design'))
            design_image = primary_design.get('design_image')
            
            # Get original room image - check multiple possible fields
            original_room_image = (
                primary_design.get('original_image') or
                lead.get('room_image') or
                lead.get('original_image') or
                lead.get('image')
            )
            
            # Create or update order
            if existing_order_id:
                # Update existing order
                cur.execute("""
                    UPDATE orders SET
                        total_amount = %s,
                        customer_type = %s,
                        admin_notes = %s,
                        design_name = %s,
                        design_image = %s,
                        original_price = %s,
                        discount_percentage = %s,
                        discount_amount = %s,
                        items_json = %s,
                        delivery_address = %s
                    WHERE id = %s
                """, (
                    float(final_price),
                    customer_type,
                    admin_notes,
                    design_name,
                    design_image,
                    float(original_price),
                    float(discount_percentage),
                    float(discount_amount),
                    json.dumps(items),
                    lead.get('location'),
                    existing_order_id
                ))
                
                order_id = existing_order_id
                
                # Delete old order items
                cur.execute("DELETE FROM order_items WHERE order_id = %s", (order_id,))
                
                # Insert updated order items
                for item in items:
                    cur.execute("""
                        INSERT INTO order_items (
                            order_id,
                            product_id,
                            quantity,
                            price_at_purchase,
                            product_name
                        ) VALUES (%s, NULL, %s, %s, %s)
                    """, (order_id, item['quantity'], item['price'], item['name']))
                
            else:
                # Create new order
                cur.execute("""
                    INSERT INTO orders (
                        quotation_id,
                        user_id,
                        order_date,
                        total_amount,
                        status,
                        status_code,
                        order_source,
                        customer_type,
                        customer_name,
                        customer_phone,
                        user_email,
                        admin_created_by,
                        requires_payment,
                        admin_notes,
                        shipping_name,
                        shipping_phone,
                        design_name,
                        design_image,
                        original_price,
                        discount_percentage,
                        discount_amount,
                        items_json,
                        delivery_address
                    ) VALUES (
                        %s, NULL, CURRENT_TIMESTAMP, %s, 'Pending Confirmation', 'pending_confirmation',
                        'quotation_order', %s, %s, %s, %s, %s, FALSE, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s
                    )
                    RETURNING id
                """, (
                    lead['id'],
                    float(final_price),
                    customer_type,
                    lead['customer_name'],
                    lead['customer_phone'],
                    lead.get('customer_email'),
                    current_user.id,
                    admin_notes,
                    lead['customer_name'],
                    lead['customer_phone'],
                    design_name,
                    design_image,
                    float(original_price),
                    float(discount_percentage),
                    float(discount_amount),
                    json.dumps(items),
                    lead.get('location')
                ))
                
                order_id = cur.fetchone()['id']
                
                # Create order items for each product
                for item in items:
                    cur.execute("""
                        INSERT INTO order_items (
                            order_id,
                            product_id,
                            quantity,
                            price_at_purchase,
                            product_name
                        ) VALUES (%s, NULL, %s, %s, %s)
                    """, (order_id, item['quantity'], item['price'], item['name']))
                
                # Update quotation with order info
                cur.execute("""
                    UPDATE leads
                    SET order_created = TRUE,
                        order_id = %s,
                        order_created_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (order_id, lead['id']))
            
            # Log status history
            if not existing_order_id:
                # Only log for new orders
                cur.execute("""
                    INSERT INTO order_status_history (
                        order_id,
                        old_status,
                        new_status,
                        changed_by,
                        notes
                    ) VALUES (%s, NULL, %s, %s, %s)
                """, (
                    order_id,
                    'pending_confirmation',
                    current_user.id,
                    f'Order created from quotation. Customer: {lead["customer_name"]}, Design: {design_name}'
                ))
            else:
                # Log update for existing orders
                cur.execute("""
                    INSERT INTO order_status_history (
                        order_id,
                        old_status,
                        new_status,
                        changed_by,
                        notes
                    ) VALUES (%s, %s, %s, %s, %s)
                """, (
                    order_id,
                    'pending_confirmation',
                    'pending_confirmation',
                    current_user.id,
                    f'Order updated from quotation. Discount: {discount_percentage}%, Final Price: ₹{final_price}'
                ))
            
            conn.commit()
            
            # Send professional email
            email_sent = False
            if lead.get('customer_email'):
                try:
                    from email_helper import send_professional_order_email
                    
                    quotation_url = f"{request.url_root}quotation/{share_token}"
                    
                    # Fix item image paths to include static/ prefix and full URL
                    items_with_full_urls = []
                    for item in items:
                        item_copy = item.copy()
                        if item_copy.get('image'):
                            # Add static/ prefix if not present
                            img_path = item_copy['image']
                            if not img_path.startswith('static/'):
                                img_path = f"static/{img_path}"
                            item_copy['image'] = f"{request.url_root}{img_path}"
                        items_with_full_urls.append(item_copy)
                    
                    # Fix design image URL
                    design_image_url = None
                    if design_image:
                        if design_image.startswith('http'):
                            design_image_url = design_image
                        elif design_image.startswith('static/'):
                            design_image_url = f"{request.url_root}{design_image}"
                        else:
                            design_image_url = f"{request.url_root}static/{design_image}"
                    
                    # Fix original room image URL
                    original_room_image_url = None
                    if original_room_image:
                        if original_room_image.startswith('http'):
                            original_room_image_url = original_room_image
                        elif original_room_image.startswith('static/'):
                            original_room_image_url = f"{request.url_root}{original_room_image}"
                        else:
                            original_room_image_url = f"{request.url_root}static/{original_room_image}"
                    
                    order_data = {
                        'customer_name': lead['customer_name'],
                        'customer_email': lead['customer_email'],
                        'customer_phone': lead['customer_phone'],
                        'order_id': order_id,
                        'design_name': design_name,
                        'design_image': design_image_url,
                        'original_room_image': original_room_image_url,
                        'items': items_with_full_urls,
                        'original_price': float(original_price),
                        'discount_percentage': float(discount_percentage),
                        'discount_amount': float(discount_amount),
                        'final_price': float(final_price),
                        'delivery_address': lead.get('location'),
                        'comments': lead.get('notes'),
                        'quotation_url': quotation_url
                    }
                    
                    email_sent = send_professional_order_email(order_data)
                    
                    # Log email notification
                    cur.execute("""
                        INSERT INTO email_notifications (
                            order_id,
                            notification_type,
                            recipient_email,
                            recipient_phone,
                            subject,
                            status
                        ) VALUES (%s, %s, %s, %s, %s, %s)
                    """, (
                        order_id,
                        'order_updated' if existing_order_id else 'order_created',
                        lead['customer_email'],
                        lead['customer_phone'],
                        f'Order {"Updated" if existing_order_id else "Confirmation"} #{order_id}',
                        'sent' if email_sent else 'failed'
                    ))
                    conn.commit()
                except Exception as e:
                    print(f"Error sending email: {e}")
            
            return jsonify({
                'success': True,
                'message': f'Order #{order_id} {"updated" if existing_order_id else "created"} successfully from quotation',
                'order_id': order_id,
                'email_sent': email_sent,
                'action': 'updated' if existing_order_id else 'created'
            }), 200 if existing_order_id else 201
            
        except Exception as e:
            conn.rollback()
            print(f"Error creating order from quotation: {e}")
            import traceback
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': f'Error creating order: {str(e)}'
            }), 500
        finally:
            conn.close()
            
    except Exception as e:
        print(f"Error in create_order_from_quotation: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'message': f'Server error: {str(e)}'
        }), 500


# Export blueprint
def register_quotation_order_routes(app, db_connection_func):
    """Register quotation order routes with the Flask app"""
    set_db_connection_func(db_connection_func)
    app.register_blueprint(quotation_order_bp)
    print("✅ Quotation Order routes registered")

# Made with Bob
