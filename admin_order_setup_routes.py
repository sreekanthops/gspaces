"""
Admin Order Setup Routes
Handles creation of orders by admin without payment requirement
"""

from flask import Blueprint, request, jsonify, render_template, flash, redirect, url_for
from flask_login import login_required, current_user
from psycopg2.extras import RealDictCursor
from datetime import datetime
import re

# Create blueprint
admin_order_setup_bp = Blueprint('admin_order_setup', __name__)

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


def validate_phone_number(phone):
    """Validate phone number format"""
    # Remove spaces, dashes, and parentheses
    phone = re.sub(r'[\s\-\(\)]', '', phone)
    # Check if it's 10-15 digits
    if re.match(r'^\+?\d{10,15}$', phone):
        return True
    return False


def send_order_created_email(order_data):
    """Send email notification when order is created"""
    try:
        from email_helper import send_admin_order_notification
        return send_admin_order_notification(
            customer_email=order_data.get('customer_email'),
            customer_name=order_data['customer_name'],
            customer_phone=order_data['customer_phone'],
            order_id=order_data['order_id'],
            product_name=order_data['product_name'],
            quantity=order_data.get('quantity', 1),
            comments=order_data.get('comments', ''),
            notification_type='order_created'
        )
    except Exception as e:
        print(f"Error sending order created email: {e}")
        return False


def send_order_status_update_email(order_data, old_status, new_status):
    """Send email notification when order status is updated"""
    try:
        from email_helper import send_admin_order_notification
        return send_admin_order_notification(
            customer_email=order_data.get('customer_email'),
            customer_name=order_data['customer_name'],
            customer_phone=order_data['customer_phone'],
            order_id=order_data['order_id'],
            product_name=order_data['product_name'],
            old_status=old_status,
            new_status=new_status,
            notification_type='status_update'
        )
    except Exception as e:
        print(f"Error sending status update email: {e}")
        return False


@admin_order_setup_bp.route('/admin/orders/create-setup', methods=['POST'])
@login_required
def create_order_setup():
    """Create a new order from admin without payment requirement"""
    
    # Check admin privileges
    if not current_user.is_admin:
        return jsonify({
            'success': False,
            'message': 'Access denied. Admin privileges required.'
        }), 403
    
    try:
        # Get form data
        data = request.get_json() if request.is_json else request.form
        
        customer_name = data.get('customer_name', '').strip()
        customer_phone = data.get('customer_phone', '').strip()
        customer_type = data.get('customer_type', '').strip()
        customer_email = data.get('customer_email', '').strip()
        product_id = data.get('product_id')
        quantity = int(data.get('quantity', 1))
        comments = data.get('comments', '').strip()
        admin_notes = data.get('admin_notes', '').strip()
        
        # Validation
        errors = []
        
        if not customer_name or len(customer_name) < 2:
            errors.append('Customer name must be at least 2 characters')
        
        if not customer_phone or not validate_phone_number(customer_phone):
            errors.append('Valid phone number is required (10-15 digits)')
        
        if not customer_type:
            errors.append('Customer type is required')
        
        valid_customer_types = ['walk-in', 'phone_order', 'referral', 'repeat_customer', 'corporate']
        if customer_type not in valid_customer_types:
            errors.append('Invalid customer type')
        
        if not product_id:
            errors.append('Product selection is required')
        
        if quantity < 1:
            errors.append('Quantity must be at least 1')
        
        if errors:
            return jsonify({
                'success': False,
                'message': 'Validation failed',
                'errors': errors
            }), 400
        
        # Connect to database
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Database connection failed'
            }), 500
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get product details
            cur.execute("""
                SELECT id, name, price, category
                FROM products
                WHERE id = %s
            """, (product_id,))
            
            product = cur.fetchone()
            
            if not product:
                return jsonify({
                    'success': False,
                    'message': 'Product not found'
                }), 404
            
            # Calculate total amount
            total_amount = float(product['price']) * quantity
            
            # Create order
            cur.execute("""
                INSERT INTO orders (
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
                    shipping_phone
                ) VALUES (
                    NULL,
                    CURRENT_TIMESTAMP,
                    %s,
                    'Pending Confirmation',
                    'pending_confirmation',
                    'admin_created',
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    FALSE,
                    %s,
                    %s,
                    %s
                )
                RETURNING id
            """, (
                total_amount,
                customer_type,
                customer_name,
                customer_phone,
                customer_email if customer_email else None,
                current_user.id,
                admin_notes,
                customer_name,
                customer_phone
            ))
            
            order_id = cur.fetchone()['id']
            
            # Create order item
            cur.execute("""
                INSERT INTO order_items (
                    order_id,
                    product_id,
                    quantity,
                    price_at_purchase,
                    product_name
                ) VALUES (%s, %s, %s, %s, %s)
            """, (order_id, product_id, quantity, product['price'], product['name']))
            
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
                f'Order created by admin. Customer: {customer_name}, Type: {customer_type}'
            ))
            
            conn.commit()
            
            # Prepare order data for email
            order_data = {
                'order_id': order_id,
                'customer_name': customer_name,
                'customer_phone': customer_phone,
                'customer_email': customer_email,
                'product_name': product['name'],
                'quantity': quantity,
                'comments': comments,
                'total_amount': total_amount
            }
            
            # Send email notification if email provided
            email_sent = False
            if customer_email:
                email_sent = send_order_created_email(order_data)
                
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
                    customer_email,
                    customer_phone,
                    f'Order Confirmation - #{order_id}',
                    'sent' if email_sent else 'failed'
                ))
                conn.commit()
            
            return jsonify({
                'success': True,
                'message': f'Order #{order_id} created successfully',
                'order_id': order_id,
                'email_sent': email_sent
            }), 201
            
        except Exception as e:
            conn.rollback()
            print(f"Error creating order: {e}")
            return jsonify({
                'success': False,
                'message': f'Error creating order: {str(e)}'
            }), 500
        finally:
            conn.close()
            
    except Exception as e:
        print(f"Error in create_order_setup: {e}")
        return jsonify({
            'success': False,
            'message': f'Server error: {str(e)}'
        }), 500


@admin_order_setup_bp.route('/admin/orders/<int:order_id>/update-status', methods=['POST'])
@login_required
def update_admin_order_status(order_id):
    """Update status of an admin-created order"""
    
    if not current_user.is_admin:
        return jsonify({
            'success': False,
            'message': 'Access denied'
        }), 403
    
    try:
        data = request.get_json() if request.is_json else request.form
        new_status = data.get('status', '').strip()
        notes = data.get('notes', '').strip()
        send_notification = data.get('send_notification', False)
        
        if not new_status:
            return jsonify({
                'success': False,
                'message': 'Status is required'
            }), 400
        
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Database connection failed'
            }), 500
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get current order details
            cur.execute("""
                SELECT o.*, u.name as admin_name
                FROM orders o
                LEFT JOIN users u ON u.id = o.admin_created_by
                WHERE o.id = %s
            """, (order_id,))
            
            order = cur.fetchone()
            
            if not order:
                return jsonify({
                    'success': False,
                    'message': 'Order not found'
                }), 404
            
            old_status = order['status_code']
            
            # Update order status
            cur.execute("""
                UPDATE orders
                SET status_code = %s,
                    status = %s,
                    status_updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (new_status, new_status.replace('_', ' ').title(), order_id))
            
            # Log status change
            cur.execute("""
                INSERT INTO order_status_history (
                    order_id,
                    old_status,
                    new_status,
                    changed_by,
                    notes,
                    notification_sent
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                order_id,
                old_status,
                new_status,
                current_user.id,
                notes,
                send_notification
            ))
            
            conn.commit()
            
            # Send email notification if requested and email available
            email_sent = False
            if send_notification and order.get('user_email'):
                # Get product name
                cur.execute("""
                    SELECT p.name
                    FROM order_items oi
                    JOIN products p ON p.id = oi.product_id
                    WHERE oi.order_id = %s
                    LIMIT 1
                """, (order_id,))
                
                product = cur.fetchone()
                
                order_data = {
                    'order_id': order_id,
                    'customer_name': order['customer_name'],
                    'customer_phone': order['customer_phone'],
                    'customer_email': order['user_email'],
                    'product_name': product['name'] if product else 'Product'
                }
                
                email_sent = send_order_status_update_email(
                    order_data,
                    old_status,
                    new_status
                )
                
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
                    'status_update',
                    order['user_email'],
                    order['customer_phone'],
                    f'Order Status Update - #{order_id}',
                    'sent' if email_sent else 'failed'
                ))
                conn.commit()
            
            return jsonify({
                'success': True,
                'message': 'Order status updated successfully',
                'email_sent': email_sent
            }), 200
            
        except Exception as e:
            conn.rollback()
            print(f"Error updating order status: {e}")
            return jsonify({
                'success': False,
                'message': f'Error updating status: {str(e)}'
            }), 500
        finally:
            conn.close()
            
    except Exception as e:
        print(f"Error in update_admin_order_status: {e}")
        return jsonify({
            'success': False,
            'message': f'Server error: {str(e)}'
        }), 500


@admin_order_setup_bp.route('/admin/orders/get-product-details/<int:product_id>')
@login_required
def get_product_details(product_id):
    """Get product details for order setup modal"""
    
    if not current_user.is_admin:
        return jsonify({
            'success': False,
            'message': 'Access denied'
        }), 403
    
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Database connection failed'
            }), 500
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            cur.execute("""
                SELECT id, name, price, category, description
                FROM products
                WHERE id = %s
            """, (product_id,))
            
            product = cur.fetchone()
            
            if not product:
                return jsonify({
                    'success': False,
                    'message': 'Product not found'
                }), 404
            
            return jsonify({
                'success': True,
                'product': dict(product)
            }), 200
            
        finally:
            conn.close()
            
    except Exception as e:
        print(f"Error getting product details: {e}")
        return jsonify({
            'success': False,
            'message': f'Server error: {str(e)}'
        }), 500


# Export blueprint
def register_admin_order_setup_routes(app, db_connection_func):
    """Register admin order setup routes with the Flask app"""
    set_db_connection_func(db_connection_func)
    app.register_blueprint(admin_order_setup_bp)
    print("✅ Admin Order Setup routes registered")

# Made with Bob
