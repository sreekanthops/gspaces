from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor
import os

sale_bp = Blueprint('sale', __name__)

# Database Configuration
DB_NAME = os.getenv("DB_NAME", "gspaces")
DB_USER = os.getenv("DB_USER", "sri")
DB_PASSWORD = os.getenv("DB_PASSWORD", "gspaces2025")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

def connect_to_db():
    """Connect to PostgreSQL database"""
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        return conn
    except Exception as e:
        print(f"DB connection error: {e}")
        return None

def get_active_sale_products():
    """Get all active sale products with time remaining"""
    conn = connect_to_db()
    if not conn:
        return []
    
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    now = datetime.now()
    
    query = """
        SELECT 
            sp.*,
            p.name as product_name,
            p.description as product_description,
            p.image_url as product_image,
            p.category_id,
            c.name as category_name
        FROM sale_products sp
        JOIN products p ON sp.product_id = p.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE sp.is_active = TRUE
        AND sp.sale_start_time <= %s
        AND sp.sale_end_time > %s
        ORDER BY sp.sale_end_time ASC
    """
    
    cursor.execute(query, (now, now))
    sale_products = cursor.fetchall()
    
    # Calculate time remaining for each product
    for product in sale_products:
        time_remaining = product['sale_end_time'] - now
        product['time_remaining_seconds'] = int(time_remaining.total_seconds())
        product['days'] = time_remaining.days
        product['hours'] = time_remaining.seconds // 3600
        product['minutes'] = (time_remaining.seconds % 3600) // 60
        product['seconds'] = time_remaining.seconds % 60
    
    cursor.close()
    conn.close()
    
    return sale_products

@sale_bp.route('/sale')
def sale_products():
    """Public sale products page"""
    products = get_active_sale_products()
    return render_template('sale_products.html', products=products)

@sale_bp.route('/admin/sale-products')
@login_required
def admin_sale_products():
    """Admin page to manage sale products"""
    if not current_user.is_admin:
        flash('Access denied. Admin privileges required.', 'danger')
        return redirect(url_for('index'))
    
    conn = connect_to_db()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('index'))
    
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # Get all sale products
    query = """
        SELECT 
            sp.*,
            p.name as product_name,
            p.image_url as product_image
        FROM sale_products sp
        JOIN products p ON sp.product_id = p.id
        ORDER BY sp.created_at DESC
    """
    cursor.execute(query)
    sale_products = cursor.fetchall()
    
    # Get all products for dropdown
    cursor.execute("SELECT id, name, price FROM products ORDER BY name")
    all_products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin_sale_products.html', 
                         sale_products=sale_products,
                         all_products=all_products)

@sale_bp.route('/admin/sale-products/add', methods=['POST'])
@login_required
def add_sale_product():
    """Add a new sale product"""
    if not current_user.is_admin:
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    try:
        product_id = request.form.get('product_id')
        sale_price = float(request.form.get('sale_price', 0))
        original_price = float(request.form.get('original_price', 0))
        sale_duration_hours = int(request.form.get('sale_duration_hours', 24))
        contact_phone = request.form.get('contact_phone', '+919876543210')
        contact_whatsapp = request.form.get('contact_whatsapp', '+919876543210')
        
        # Calculate discount percentage
        discount_percentage = int(((original_price - sale_price) / original_price) * 100)
        
        # Set sale times
        sale_start_time = datetime.now()
        sale_end_time = sale_start_time + timedelta(hours=sale_duration_hours)
        
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'danger')
            return redirect(url_for('sale.admin_sale_products'))
        
        cursor = conn.cursor()
        
        query = """
            INSERT INTO sale_products 
            (product_id, sale_price, original_price, discount_percentage, 
             sale_start_time, sale_end_time, contact_phone, contact_whatsapp, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, TRUE)
        """
        
        cursor.execute(query, (product_id, sale_price, original_price, discount_percentage,
                              sale_start_time, sale_end_time, contact_phone, contact_whatsapp))
        conn.commit()
        
        cursor.close()
        conn.close()
        
        flash('Sale product added successfully!', 'success')
        return redirect(url_for('products'))
        
    except Exception as e:
        flash(f'Error adding sale product: {str(e)}', 'danger')
        return redirect(url_for('sale.admin_sale_products'))

@sale_bp.route('/admin/sale-products/delete/<int:sale_id>', methods=['POST'])
@login_required
def delete_sale_product(sale_id):
    """Delete a sale product"""
    if not current_user.is_admin:
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    try:
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'danger')
            return redirect(url_for('sale.admin_sale_products'))
        
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM sale_products WHERE id = %s", (sale_id,))
        conn.commit()
        
        cursor.close()
        conn.close()
        
        flash('Product removed from sale successfully!', 'success')
        return redirect(url_for('products'))
        
    except Exception as e:
        flash(f'Error deleting sale product: {str(e)}', 'danger')
        return redirect(url_for('sale.admin_sale_products'))

@sale_bp.route('/admin/sale-products/toggle/<int:sale_id>', methods=['POST'])
@login_required
def toggle_sale_product(sale_id):
    """Toggle sale product active status"""
    if not current_user.is_admin:
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    try:
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database connection error'}), 500
        
        cursor = conn.cursor()
        
        cursor.execute("UPDATE sale_products SET is_active = NOT is_active WHERE id = %s", (sale_id,))
        conn.commit()
        
        cursor.close()
        conn.close()
        
        return jsonify({'success': True})
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@sale_bp.route('/api/sale-products/time-remaining')
def get_time_remaining():
    """API endpoint to get updated time remaining for all active sales"""
    products = get_active_sale_products()
    
    result = []
    for product in products:
        result.append({
            'id': product['id'],
            'time_remaining_seconds': product['time_remaining_seconds'],
            'days': product['days'],
            'hours': product['hours'],
            'minutes': product['minutes'],
            'seconds': product['seconds']
        })
    
    return jsonify(result)

# Made with Bob
