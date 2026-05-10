"""
Leads/Quotation Management System Routes
Handles all lead creation, editing, and quotation generation
"""

import os
import secrets
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, send_file
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

# Create blueprint
leads_bp = Blueprint('leads', __name__)

# Database connection function (will be set from main.py)
get_db_connection = None

# Upload configuration
LEADS_UPLOAD_FOLDER = os.path.join('static', 'img', 'leads')
REFERENCE_FOLDER = os.path.join(LEADS_UPLOAD_FOLDER, 'reference')
DESIGNS_FOLDER = os.path.join(LEADS_UPLOAD_FOLDER, 'designs')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

# Create upload directories
os.makedirs(REFERENCE_FOLDER, exist_ok=True)
os.makedirs(DESIGNS_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def admin_required(f):
    """Decorator to require admin access"""
    @login_required
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin:
            flash('Access denied. Admin privileges required.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
    return decorated_function

# ============================================================================
# ADMIN ROUTES - Leads Management
# ============================================================================

@leads_bp.route('/admin/leads')
@admin_required
def admin_leads_list():
    """Display all leads with filtering"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Get filter parameters
    status_filter = request.args.get('status', 'all')
    search = request.args.get('search', '')
    
    # Build query
    query = """
        SELECT l.*, u.name as created_by_name,
               COUNT(DISTINCT ld.id) as design_count
        FROM leads l
        LEFT JOIN users u ON l.created_by = u.id
        LEFT JOIN lead_designs ld ON l.id = ld.lead_id
        WHERE 1=1
    """
    params = []
    
    if status_filter != 'all':
        query += " AND l.status = %s"
        params.append(status_filter)
    
    if search:
        query += " AND (l.customer_name ILIKE %s OR l.customer_email ILIKE %s OR l.project_name ILIKE %s)"
        search_param = f'%{search}%'
        params.extend([search_param, search_param, search_param])
    
    query += " GROUP BY l.id, u.name ORDER BY l.created_at DESC"
    
    cur.execute(query, params)
    leads = cur.fetchall()
    
    # Get status counts
    cur.execute("SELECT status, COUNT(*) as count FROM leads GROUP BY status")
    status_counts = {row['status']: row['count'] for row in cur.fetchall()}
    
    cur.close()
    conn.close()
    
    return render_template('admin_leads.html',
                         leads=leads,
                         status_counts=status_counts,
                         current_status=status_filter,
                         search=search)

@leads_bp.route('/admin/leads/create', methods=['GET', 'POST'])
@admin_required
def create_lead():
    """Create a new lead"""
    if request.method == 'POST':
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            customer_name = request.form.get('customer_name')
            customer_email = request.form.get('customer_email')
            customer_phone = request.form.get('customer_phone')
            project_name = request.form.get('project_name')
            notes = request.form.get('notes', '')
            design_category = request.form.get('design_category', 'office')
            
            # Handle reference image upload
            reference_image = None
            if 'reference_image' in request.files:
                file = request.files['reference_image']
                if file and file.filename and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    filename = f"ref_{timestamp}_{filename}"
                    filepath = os.path.join(REFERENCE_FOLDER, filename)
                    file.save(filepath)
                    reference_image = f"img/leads/reference/{filename}"
            
            # Generate unique share token
            share_token = secrets.token_urlsafe(16)
            
            # Insert lead
            cur.execute("""
                INSERT INTO leads (customer_name, customer_email, customer_phone,
                                 project_name, reference_image, notes, share_token,
                                 created_by, design_category)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (customer_name, customer_email, customer_phone, project_name,
                  reference_image, notes, share_token, current_user.id, design_category))
            
            lead_id = cur.fetchone()[0]
            conn.commit()
            
            flash('Lead created successfully!', 'success')
            return redirect(url_for('leads.edit_lead', lead_id=lead_id))
            
        except Exception as e:
            conn.rollback()
            flash(f'Error creating lead: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
    
    return render_template('create_lead.html')

@leads_bp.route('/admin/leads/<int:lead_id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_lead():
    """Edit lead and manage designs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    lead_id = request.args.get('lead_id') or request.view_args.get('lead_id')
    
    if request.method == 'POST':
        try:
            # Update lead basic info
            customer_name = request.form.get('customer_name')
            customer_email = request.form.get('customer_email')
            customer_phone = request.form.get('customer_phone')
            project_name = request.form.get('project_name')
            notes = request.form.get('notes', '')
            status = request.form.get('status', 'draft')
            discount_type = request.form.get('discount_type', 'none')
            discount_value = float(request.form.get('discount_value', 0))
            
            # Handle new reference image if uploaded
            reference_image_update = ""
            if 'reference_image' in request.files:
                file = request.files['reference_image']
                if file and file.filename and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    filename = f"ref_{timestamp}_{filename}"
                    filepath = os.path.join(REFERENCE_FOLDER, filename)
                    file.save(filepath)
                    reference_image_update = f", reference_image = 'img/leads/reference/{filename}'"
            
            cur.execute(f"""
                UPDATE leads
                SET customer_name = %s, customer_email = %s, customer_phone = %s,
                    project_name = %s, notes = %s, status = %s,
                    discount_type = %s, discount_value = %s
                    {reference_image_update}
                WHERE id = %s
            """, (customer_name, customer_email, customer_phone, project_name,
                  notes, status, discount_type, discount_value, lead_id))
            
            conn.commit()
            flash('Lead updated successfully!', 'success')
            
        except Exception as e:
            conn.rollback()
            flash(f'Error updating lead: {str(e)}', 'danger')
    
    # Fetch lead details
    cur.execute("SELECT * FROM leads WHERE id = %s", (lead_id,))
    lead = cur.fetchone()
    
    if not lead:
        flash('Lead not found', 'danger')
        return redirect(url_for('leads.admin_leads_list'))
    
    # Fetch designs for this lead
    cur.execute("""
        SELECT ld.*, di.*
        FROM lead_designs ld
        LEFT JOIN design_items di ON ld.id = di.design_id
        WHERE ld.lead_id = %s
        ORDER BY ld.design_order, ld.id
    """, (lead_id,))
    designs = cur.fetchall()
    
    # Fetch custom fields for each design
    design_custom_fields = {}
    for design in designs:
        if design['id']:
            cur.execute("""
                SELECT * FROM design_custom_fields
                WHERE design_id = %s
            """, (design['id'],))
            design_custom_fields[design['id']] = cur.fetchall()
    
    # Fetch pricing rules
    cur.execute("SELECT * FROM pricing_rules ORDER BY item_category, item_type")
    pricing_rules = cur.fetchall()
    
    # Fetch default items and prices from default_items table
    cur.execute("""
        SELECT id, item_name, item_slug, icon_emoji, icon_image,
               default_price, description, display_order, is_active
        FROM default_items
        WHERE is_active = TRUE
        ORDER BY display_order, item_name
    """)
    default_items_list = cur.fetchall()
    
    # Create default_prices dict for backward compatibility
    default_prices = {row['item_slug']: row['default_price'] for row in default_items_list}
    
    cur.close()
    conn.close()
    
    return render_template('edit_lead_simple.html',
                         lead=lead,
                         designs=designs,
                         design_custom_fields=design_custom_fields,
                         pricing_rules=pricing_rules,
                         default_prices=default_prices,
                         default_items=default_items_list)

@leads_bp.route('/admin/leads/<int:lead_id>/design/add', methods=['POST'])
@admin_required
def add_design():
    """Add a new design to a lead"""
    lead_id = request.form.get('lead_id') or request.view_args.get('lead_id')
    design_name = request.form.get('design_name', 'New Design')
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Handle design image upload
        design_image = None
        if 'design_image' in request.files:
            file = request.files['design_image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"design_{timestamp}_{filename}"
                filepath = os.path.join(DESIGNS_FOLDER, filename)
                file.save(filepath)
                design_image = f"img/leads/designs/{filename}"
        
        # Get next order number
        cur.execute("SELECT COALESCE(MAX(design_order), 0) + 1 FROM lead_designs WHERE lead_id = %s", (lead_id,))
        next_order = cur.fetchone()[0]
        
        # Insert design
        cur.execute("""
            INSERT INTO lead_designs (lead_id, design_name, design_image, design_order)
            VALUES (%s, %s, %s, %s)
            RETURNING id
        """, (lead_id, design_name, design_image, next_order))
        
        design_id = cur.fetchone()[0]
        
        # Create empty design_items record
        cur.execute("""
            INSERT INTO design_items (design_id)
            VALUES (%s)
        """, (design_id,))
        
        conn.commit()
        flash('Design added successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error adding design: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/admin/default-prices', methods=['GET', 'POST'])
@admin_required
def manage_default_prices():
    """Manage default prices and items - Main page"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    if request.method == 'POST':
        try:
            # Update all default prices
            for key, value in request.form.items():
                if key.startswith('price_'):
                    item_slug = key.replace('price_', '')
                    price = float(value)
                    
                    cur.execute("""
                        UPDATE default_items
                        SET default_price = %s, updated_at = CURRENT_TIMESTAMP
                        WHERE item_slug = %s
                    """, (price, item_slug))
            
            conn.commit()
            flash('Default prices updated successfully!', 'success')
            return redirect(url_for('leads.manage_default_prices'))
            
        except Exception as e:
            conn.rollback()
            flash(f'Error updating prices: {str(e)}', 'danger')
    
    # Fetch all items from default_items table
    cur.execute("""
        SELECT id, item_name, item_slug, icon_emoji, icon_image,
               default_price, description, display_order, is_active
        FROM default_items
        ORDER BY display_order, item_name
    """)
    items = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin_default_prices.html', items=items)

@leads_bp.route('/admin/default-items/add', methods=['POST'])
@admin_required
def add_default_item():
    """Add a new default item"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        item_name = request.form.get('item_name')
        item_slug = request.form.get('item_slug')
        icon_emoji = request.form.get('icon_emoji', '📦')
        default_price = float(request.form.get('default_price', 0))
        description = request.form.get('description', '')
        display_order = int(request.form.get('display_order', 0))
        is_active = 'is_active' in request.form
        
        # Handle icon image upload
        icon_image = None
        if 'icon_image' in request.files:
            file = request.files['icon_image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"icon_{item_slug}_{timestamp}_{filename}"
                
                # Create icons directory if it doesn't exist
                icons_folder = os.path.join('static', 'img', 'icons')
                os.makedirs(icons_folder, exist_ok=True)
                
                filepath = os.path.join(icons_folder, filename)
                file.save(filepath)
                icon_image = f"img/icons/{filename}"
        
        # Insert new item
        cur.execute("""
            INSERT INTO default_items
            (item_name, item_slug, icon_emoji, icon_image, default_price,
             description, display_order, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (item_name, item_slug, icon_emoji, icon_image, default_price,
              description, display_order, is_active))
        
        conn.commit()
        flash(f'Item "{item_name}" added successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error adding item: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.manage_default_prices'))

@leads_bp.route('/admin/default-items/update', methods=['POST'])
@admin_required
def update_default_item():
    """Update an existing default item"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        item_id = int(request.form.get('item_id'))
        item_name = request.form.get('item_name')
        item_slug = request.form.get('item_slug')
        icon_emoji = request.form.get('icon_emoji', '📦')
        default_price = float(request.form.get('default_price', 0))
        description = request.form.get('description', '')
        display_order = int(request.form.get('display_order', 0))
        is_active = 'is_active' in request.form
        
        # Handle icon image upload
        icon_image_update = ""
        if 'icon_image' in request.files:
            file = request.files['icon_image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"icon_{item_slug}_{timestamp}_{filename}"
                
                # Create icons directory if it doesn't exist
                icons_folder = os.path.join('static', 'img', 'icons')
                os.makedirs(icons_folder, exist_ok=True)
                
                filepath = os.path.join(icons_folder, filename)
                file.save(filepath)
                icon_image_update = f", icon_image = 'img/icons/{filename}'"
        
        # Update item
        cur.execute(f"""
            UPDATE default_items
            SET item_name = %s, item_slug = %s, icon_emoji = %s,
                default_price = %s, description = %s, display_order = %s,
                is_active = %s, updated_at = CURRENT_TIMESTAMP
                {icon_image_update}
            WHERE id = %s
        """, (item_name, item_slug, icon_emoji, default_price, description,
              display_order, is_active, item_id))
        
        conn.commit()
        flash(f'Item "{item_name}" updated successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error updating item: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.manage_default_prices'))

@leads_bp.route('/admin/default-items/delete', methods=['POST'])
@admin_required
def delete_default_item():
    """Delete a default item"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        item_id = int(request.form.get('item_id'))
        
        # Delete item
        cur.execute("DELETE FROM default_items WHERE id = %s", (item_id,))
        
        conn.commit()
        flash('Item deleted successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error deleting item: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.manage_default_prices'))

# Continue in next message due to length...

# Made with Bob
