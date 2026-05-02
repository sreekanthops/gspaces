"""
Simplified Leads/Quotation System - MVP Version
Admin creates leads with designs and manual pricing
"""

import os
import secrets
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

# Blueprint
leads_bp = Blueprint('leads', __name__)

# Will be set from main.py
get_db_connection = None

# Upload folders
LEADS_FOLDER = os.path.join('static', 'img', 'leads')
REFERENCE_FOLDER = os.path.join(LEADS_FOLDER, 'reference')
DESIGNS_FOLDER = os.path.join(LEADS_FOLDER, 'designs')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

os.makedirs(REFERENCE_FOLDER, exist_ok=True)
os.makedirs(DESIGNS_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def admin_required(f):
    @login_required
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin:
            flash('Admin access required', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
    return decorated_function

# ============================================================================
# ADMIN ROUTES
# ============================================================================

@leads_bp.route('/admin/leads')
@admin_required
def admin_leads_list():
    """List all leads"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    cur.execute("""
        SELECT l.*, 
               COUNT(ld.id) as design_count,
               SUM(ld.price) as total_value
        FROM leads l
        LEFT JOIN lead_designs ld ON l.id = ld.lead_id
        GROUP BY l.id
        ORDER BY l.created_at DESC
    """)
    leads = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin_leads_simple.html', leads=leads)

@leads_bp.route('/admin/leads/create', methods=['GET', 'POST'])
@admin_required
def create_lead():
    """Create new lead"""
    if request.method == 'POST':
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            customer_name = request.form.get('customer_name')
            customer_email = request.form.get('customer_email', '')
            customer_phone = request.form.get('customer_phone', '')
            project_name = request.form.get('project_name', '')
            notes = request.form.get('notes', '')
            
            # Handle main image
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
            
            # Generate share token
            share_token = secrets.token_urlsafe(16)
            
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
            flash(f'Error: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
    
    return render_template('create_lead_simple.html')

@leads_bp.route('/admin/leads/<int:lead_id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_lead(lead_id):
    """Edit lead and manage designs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    if request.method == 'POST':
        try:
            # Update lead info
            customer_name = request.form.get('customer_name')
            customer_email = request.form.get('customer_email', '')
            customer_phone = request.form.get('customer_phone', '')
            project_name = request.form.get('project_name', '')
            notes = request.form.get('notes', '')
            
            # Get current image
            cur.execute("SELECT reference_image FROM leads WHERE id = %s", (lead_id,))
            current_image = cur.fetchone()['reference_image']
            reference_image = current_image
            
            # Handle new image if uploaded
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
                    project_name = %s, notes = %s, reference_image = %s
                WHERE id = %s
            """, (customer_name, customer_email, customer_phone, project_name,
                  notes, reference_image, lead_id))
            
            conn.commit()
            flash('Lead updated!', 'success')
            
        except Exception as e:
            conn.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    # Fetch lead
    cur.execute("SELECT * FROM leads WHERE id = %s", (lead_id,))
    lead = cur.fetchone()
    
    if not lead:
        flash('Lead not found', 'danger')
        return redirect(url_for('leads.admin_leads_list'))
    
    # Fetch designs
    cur.execute("""
        SELECT * FROM lead_designs 
        WHERE lead_id = %s 
        ORDER BY design_order, id
    """, (lead_id,))
    designs = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('edit_lead_simple.html', lead=lead, designs=designs)

@leads_bp.route('/admin/leads/<int:lead_id>/design/add', methods=['POST'])
@admin_required
def add_design(lead_id):
    """Add design to lead"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        design_name = request.form.get('design_name', 'Design Option')
        
        # Handle design image
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
        
        # Get next order
        cur.execute("SELECT COALESCE(MAX(design_order), 0) + 1 FROM lead_designs WHERE lead_id = %s", (lead_id,))
        next_order = cur.fetchone()[0]
        
        cur.execute("""
            INSERT INTO lead_designs (lead_id, design_name, design_image, design_order)
            VALUES (%s, %s, %s, %s)
        """, (lead_id, design_name, design_image, next_order))
        
        conn.commit()
        flash('Design added!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/admin/leads/design/<int:design_id>/update', methods=['POST'])
@admin_required
def update_design(design_id):
    """Update design details"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get lead_id for redirect
        cur.execute("SELECT lead_id FROM lead_designs WHERE id = %s", (design_id,))
        lead_id = cur.fetchone()['lead_id']
        
        # Get form data
        design_name = request.form.get('design_name')
        has_table = request.form.get('has_table') == 'on'
        has_chair = request.form.get('has_chair') == 'on'
        has_plants = request.form.get('has_plants') == 'on'
        has_lighting = request.form.get('has_lighting') == 'on'
        has_storage = request.form.get('has_storage') == 'on'
        has_accessories = request.form.get('has_accessories') == 'on'
        
        table_details = request.form.get('table_details', '')
        chair_details = request.form.get('chair_details', '')
        plants_details = request.form.get('plants_details', '')
        lighting_details = request.form.get('lighting_details', '')
        storage_details = request.form.get('storage_details', '')
        accessories_details = request.form.get('accessories_details', '')
        
        price = float(request.form.get('price', 0))
        notes = request.form.get('notes', '')
        
        cur.execute("""
            UPDATE lead_designs 
            SET design_name = %s,
                has_table = %s, has_chair = %s, has_plants = %s,
                has_lighting = %s, has_storage = %s, has_accessories = %s,
                table_details = %s, chair_details = %s, plants_details = %s,
                lighting_details = %s, storage_details = %s, accessories_details = %s,
                price = %s, notes = %s
            WHERE id = %s
        """, (design_name, has_table, has_chair, has_plants, has_lighting, has_storage,
              has_accessories, table_details, chair_details, plants_details,
              lighting_details, storage_details, accessories_details, price, notes, design_id))
        
        conn.commit()
        flash('Design updated!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error: {str(e)}', 'danger')
        lead_id = request.form.get('lead_id', 1)
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/admin/leads/design/<int:design_id>/delete', methods=['POST'])
@admin_required
def delete_design(design_id):
    """Delete design"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("SELECT lead_id FROM lead_designs WHERE id = %s", (design_id,))
        result = cur.fetchone()
        lead_id = result['lead_id'] if result else 1
        
        cur.execute("DELETE FROM lead_designs WHERE id = %s", (design_id,))
        conn.commit()
        flash('Design deleted!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/quotation/<share_token>')
def view_quotation(share_token):
    """Public quotation view"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Get lead
    cur.execute("SELECT * FROM leads WHERE share_token = %s", (share_token,))
    lead = cur.fetchone()
    
    if not lead:
        return "Quotation not found", 404
    
    # Get designs
    cur.execute("""
        SELECT * FROM lead_designs 
        WHERE lead_id = %s 
        ORDER BY design_order, id
    """, (lead['id'],))
    designs = cur.fetchall()
    
    # Calculate total
    total = sum(d['price'] or 0 for d in designs)
    
    cur.close()
    conn.close()
    
    return render_template('quotation_view_simple.html', 
                         lead=lead, designs=designs, total=total)

def register_leads_routes(app, db_connection_func):
    """Register blueprint with app"""
    global get_db_connection
    get_db_connection = db_connection_func
    app.register_blueprint(leads_bp)

# Made with Bob
