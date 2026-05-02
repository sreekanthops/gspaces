"""
Leads/Quotation Management System Routes - COMPLETE VERSION
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
from decimal import Decimal

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

def calculate_item_price(item_data):
    """Calculate total price for design items"""
    total = Decimal('0.00')
    
    # Table pricing
    if item_data.get('table_enabled'):
        table_type = item_data.get('table_type', '')
        table_size = item_data.get('table_size', '')
        
        if table_type == 'iron_legs_4x2':
            total += Decimal('12000')
        elif table_type == 'iron_legs_5x2':
            total += Decimal('18000')
        elif table_type == 'wooden_legs_4x2':
            total += Decimal('15000')
        
        if item_data.get('table_with_storage'):
            total += Decimal('8000')
    
    # Chair pricing
    if item_data.get('chair_enabled'):
        chair_type = item_data.get('chair_type', 'basic')
        quantity = int(item_data.get('chair_quantity', 1))
        
        chair_prices = {
            'basic': Decimal('6000'),
            'basic_headrest': Decimal('8000'),
            'medium': Decimal('15000'),
            'high': Decimal('25000')
        }
        total += chair_prices.get(chair_type, Decimal('6000')) * quantity
    
    # Plants
    if item_data.get('mini_plants_enabled'):
        count = int(item_data.get('mini_plants_count', 0))
        total += Decimal('400') * count
    
    if item_data.get('big_plants_enabled'):
        count = int(item_data.get('big_plants_count', 0))
        total += Decimal('1000') * count
    
    # Artefacts
    if item_data.get('artefacts_enabled'):
        count = int(item_data.get('artefacts_count', 0))
        total += Decimal('700') * count
    
    # Frames
    if item_data.get('frames_enabled'):
        mini = int(item_data.get('frames_mini_count', 0))
        medium = int(item_data.get('frames_medium_count', 0))
        large = int(item_data.get('frames_large_count', 0))
        total += (Decimal('800') * mini) + (Decimal('1200') * medium) + (Decimal('2000') * large)
    
    # Table lamp
    if item_data.get('table_lamp_enabled'):
        lamp_type = item_data.get('table_lamp_type', 'basic')
        lamp_prices = {
            'basic': Decimal('1000'),
            'medium': Decimal('2000'),
            'high': Decimal('3000')
        }
        total += lamp_prices.get(lamp_type, Decimal('1000'))
    
    # Accessories
    if item_data.get('multisocket_enabled'):
        total += Decimal('1200')
    
    if item_data.get('cable_organiser_enabled'):
        total += Decimal('1200')
    
    if item_data.get('deskmat_enabled'):
        total += Decimal('1000')
    
    # Floor mat (per sq ft)
    if item_data.get('floor_mat_enabled'):
        size = item_data.get('floor_mat_size', '0x0')
        try:
            dims = size.split('x')
            sq_ft = float(dims[0]) * float(dims[1])
            total += Decimal(str(sq_ft * 500))
        except:
            pass
    
    # Profile light (per ft)
    if item_data.get('profile_light_enabled'):
        feet = float(item_data.get('profile_light_feet', 0))
        total += Decimal(str(feet * 300))
    
    if item_data.get('clock_enabled'):
        total += Decimal('1000')
    
    # Pegboard (per sq ft)
    if item_data.get('pegboard_enabled'):
        size = item_data.get('pegboard_size', '1x1')
        try:
            dims = size.split('x')
            sq_ft = float(dims[0]) * float(dims[1])
            total += Decimal(str(sq_ft * 1000))
        except:
            total += Decimal('1000')
    
    return total

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
                                 project_name, reference_image, notes, share_token, created_by)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (customer_name, customer_email, customer_phone, project_name,
                  reference_image, notes, share_token, current_user.id))
            
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
def edit_lead(lead_id):
    """Edit lead and manage designs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
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
            cur.execute("SELECT reference_image FROM leads WHERE id = %s", (lead_id,))
            current_image = cur.fetchone()['reference_image']
            reference_image = current_image
            
            if 'reference_image' in request.files:
                file = request.files['reference_image']
                if file and file.filename and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    filename = f"ref_{timestamp}_{filename}"
                    filepath = os.path.join(REFERENCE_FOLDER, filename)
                    file.save(filepath)
                    reference_image = f"img/leads/reference/{filename}"
            
            cur.execute("""
                UPDATE leads 
                SET customer_name = %s, customer_email = %s, customer_phone = %s,
                    project_name = %s, notes = %s, status = %s,
                    discount_type = %s, discount_value = %s, reference_image = %s
                WHERE id = %s
            """, (customer_name, customer_email, customer_phone, project_name,
                  notes, status, discount_type, discount_value, reference_image, lead_id))
            
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
    designs_raw = cur.fetchall()
    
    # Group designs properly
    designs = {}
    for row in designs_raw:
        design_id = row['id']
        if design_id not in designs:
            designs[design_id] = dict(row)
            designs[design_id]['items'] = dict(row) if row.get('design_id') else {}
    
    designs = list(designs.values())
    
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
    
    cur.close()
    conn.close()
    
    return render_template('edit_lead.html',
                         lead=lead,
                         designs=designs,
                         design_custom_fields=design_custom_fields,
                         pricing_rules=pricing_rules)

# Continue with more routes...

# Made with Bob
