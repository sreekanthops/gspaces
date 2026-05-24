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


def extract_items_from_quotation(lead_designs):
    """Extract all items from quotation designs"""
    items = []
    
    for design in lead_designs:
        # Table
        if design.get('has_table') and design.get('table_price', 0) > 0:
            items.append({
                'name': design.get('table_details', 'Table'),
                'quantity': design.get('table_quantity', 1),
                'price': float(design.get('table_price', 0))
            })
        
        # Chair
        if design.get('has_chair') and design.get('chair_price', 0) > 0:
            items.append({
                'name': design.get('chair_details', 'Chair'),
                'quantity': design.get('chair_quantity', 1),
                'price': float(design.get('chair_price', 0))
            })
        
        # Plants
        if design.get('has_plants') and design.get('plants_price', 0) > 0:
            items.append({
                'name': design.get('plants_details', 'Plants'),
                'quantity': design.get('plants_quantity', 1),
                'price': float(design.get('plants_price', 0))
            })
        
        # Lighting
        if design.get('has_lighting') and design.get('lighting_price', 0) > 0:
            items.append({
                'name': design.get('lighting_details', 'Lighting'),
                'quantity': design.get('lighting_quantity', 1),
                'price': float(design.get('lighting_price', 0))
            })
        
        # Storage
        if design.get('has_storage') and design.get('storage_price', 0) > 0:
            items.append({
                'name': design.get('storage_details', 'Storage'),
                'quantity': design.get('storage_quantity', 1),
                'price': float(design.get('storage_price', 0))
            })
        
        # Accessories
        if design.get('has_accessories') and design.get('accessories_price', 0) > 0:
            items.append({
                'name': design.get('accessories_details', 'Accessories'),
                'quantity': design.get('accessories_quantity', 1),
                'price': float(design.get('accessories_price', 0))
            })
        
        # Custom items
        if design.get('custom_items'):
            try:
                custom_items = json.loads(design['custom_items']) if isinstance(design['custom_items'], str) else design['custom_items']
                for item in custom_items:
                    if item.get('price', 0) > 0:
                        items.append({
                            'name': item.get('name', 'Custom Item'),
                            'quantity': item.get('quantity', 1),
                            'price': float(item.get('price', 0))
                        })
            except:
                pass
    
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
            
            # Check if order already exists
            if lead.get('order_created'):
                return jsonify({
                    'success': False,
                    'message': f'Order already created for this quotation (Order #{lead.get("order_id")})'
                }), 400
            
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
            
            # Calculate pricing
            original_price = sum(design.get('subtotal', 0) for design in lead_designs)
            
            if final_price_override:
                final_price = float(final_price_override)
                discount_amount = original_price - final_price
                if original_price > 0:
                    discount_percentage = (discount_amount / original_price) * 100
            else:
                discount_amount = (original_price * discount_percentage) / 100
                final_price = original_price - discount_amount
            
            # Get primary design details
            primary_design = lead_designs[0]
            design_name = primary_design.get('design_name', lead.get('project_name', 'Custom Design'))
            design_image = primary_design.get('design_image')
            
            # Create order
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
                final_price,
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
                original_price,
                discount_percentage,
                discount_amount,
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
            
            conn.commit()
            
            # Send professional email
            email_sent = False
            if lead.get('customer_email'):
                try:
                    from email_helper import send_professional_order_email
                    
                    quotation_url = f"{request.url_root}quotation/{share_token}"
                    
                    order_data = {
                        'customer_name': lead['customer_name'],
                        'customer_email': lead['customer_email'],
                        'customer_phone': lead['customer_phone'],
                        'order_id': order_id,
                        'design_name': design_name,
                        'design_image': f"{request.url_root}{design_image}" if design_image else None,
                        'items': items,
                        'original_price': original_price,
                        'discount_percentage': discount_percentage,
                        'discount_amount': discount_amount,
                        'final_price': final_price,
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
                        'order_created',
                        lead['customer_email'],
                        lead['customer_phone'],
                        f'Order Confirmation #{order_id}',
                        'sent' if email_sent else 'failed'
                    ))
                    conn.commit()
                except Exception as e:
                    print(f"Error sending email: {e}")
            
            return jsonify({
                'success': True,
                'message': f'Order #{order_id} created successfully from quotation',
                'order_id': order_id,
                'email_sent': email_sent
            }), 201
            
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
