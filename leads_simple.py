"""
Simplified Leads/Quotation System - MVP Version
Admin creates leads with designs and manual pricing
"""

import os
import secrets
import json
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
MEDIA_FOLDER = os.path.join(LEADS_FOLDER, 'media')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
ALLOWED_VIDEO_EXTENSIONS = {'mp4', 'webm', 'mov', 'avi'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

os.makedirs(REFERENCE_FOLDER, exist_ok=True)
os.makedirs(DESIGNS_FOLDER, exist_ok=True)
os.makedirs(MEDIA_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def allowed_media_file(filename):
    """Check if file is allowed image or video"""
    if '.' not in filename:
        return False
    ext = filename.rsplit('.', 1)[1].lower()
    return ext in ALLOWED_EXTENSIONS or ext in ALLOWED_VIDEO_EXTENSIONS

def get_media_type(filename):
    """Determine if file is image or video"""
    ext = filename.rsplit('.', 1)[1].lower()
    if ext in ALLOWED_EXTENSIONS:
        return 'image'
    elif ext in ALLOWED_VIDEO_EXTENSIONS:
        return 'video'
    return None

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
            location = request.form.get('location', '')
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
                    project_name = %s, location = %s, notes = %s, reference_image = %s
                WHERE id = %s
            """, (customer_name, customer_email, customer_phone, project_name,
                  location, notes, reference_image, lead_id))
            
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
    
    # Parse custom_items and media_files JSON for each design
    for design in designs:
        # Parse custom_items
        if design.get('custom_items'):
            try:
                design['custom_items'] = json.loads(design['custom_items'])
            except:
                design['custom_items'] = []
        else:
            design['custom_items'] = []
        
        # Parse media_files
        if design.get('media_files'):
            try:
                design['media_files'] = json.loads(design['media_files'])
            except:
                design['media_files'] = []
        else:
            design['media_files'] = []
    
    # Fetch default prices from database
    cur.execute("SELECT item_name, default_price, description FROM item_default_prices ORDER BY item_name")
    default_prices_list = cur.fetchall()
    default_prices = {row['item_name']: row['default_price'] for row in default_prices_list}
    
    cur.close()
    conn.close()
    
    return render_template('edit_lead_simple.html', lead=lead, designs=designs, default_prices=default_prices)

@leads_bp.route('/admin/leads/<int:lead_id>/design/add', methods=['POST'])
@admin_required
def add_design(lead_id):
    """Add design to lead - copies properties from first design if exists"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        design_name = request.form.get('design_name', 'Design Option')
        
        # Handle multiple media files (images and videos)
        media_files = []
        design_image = None  # Keep for backward compatibility
        
        if 'media_files' in request.files:
            files = request.files.getlist('media_files')
            for idx, file in enumerate(files):
                if file and file.filename and allowed_media_file(file.filename):
                    # Check file size
                    file.seek(0, os.SEEK_END)
                    file_size = file.tell()
                    file.seek(0)
                    
                    if file_size > MAX_FILE_SIZE:
                        flash(f'File {file.filename} exceeds 50MB limit', 'warning')
                        continue
                    
                    filename = secure_filename(file.filename)
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    filename = f"media_{timestamp}_{idx}_{filename}"
                    filepath = os.path.join(MEDIA_FOLDER, filename)
                    file.save(filepath)
                    
                    media_type = get_media_type(file.filename)
                    media_url = f"img/leads/media/{filename}"
                    
                    media_files.append({
                        'type': media_type,
                        'url': media_url,
                        'order': idx
                    })
                    
                    # Set first image as design_image for backward compatibility
                    if not design_image and media_type == 'image':
                        design_image = media_url
        
        # Fallback to single design_image if no media_files uploaded
        if not media_files and 'design_image' in request.files:
            file = request.files['design_image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"design_{timestamp}_{filename}"
                filepath = os.path.join(DESIGNS_FOLDER, filename)
                file.save(filepath)
                design_image = f"img/leads/designs/{filename}"
                media_files.append({
                    'type': 'image',
                    'url': design_image,
                    'order': 0
                })
        
        # Get first design to copy properties from (including all 18 quantity-based items)
        cur.execute("""
            SELECT has_table, table_quantity, table_price, table_details,
                   has_chair, chair_quantity, chair_price, chair_details,
                   has_plants, plants_quantity, plants_price, plants_details,
                   has_lighting, lighting_quantity, lighting_price, lighting_details,
                   has_profile_lighting, profile_lighting_quantity, profile_lighting_price, profile_lighting_details,
                   has_storage, storage_quantity, storage_price, storage_details,
                   has_accessories, accessories_quantity, accessories_price, accessories_details,
                   has_big_plants, big_plants_quantity, big_plants_price, big_plants_details,
                   has_mini_plants, mini_plants_quantity, mini_plants_price, mini_plants_details,
                   has_frames, frames_quantity, frames_price, frames_details,
                   has_wall_racks, wall_racks_quantity, wall_racks_price, wall_racks_details,
                   has_desk_mat, desk_mat_quantity, desk_mat_price, desk_mat_details,
                   has_dustbin, dustbin_quantity, dustbin_price, dustbin_details,
                   has_floor_mat, floor_mat_quantity, floor_mat_price, floor_mat_details,
                   has_keyboard, keyboard_quantity, keyboard_price, keyboard_details,
                   has_mouse, mouse_quantity, mouse_price, mouse_details,
                   has_paint, paint_quantity, paint_price, paint_details,
                   has_wardrobes, wardrobes_quantity, wardrobes_price, wardrobes_details,
                   price, notes
            FROM lead_designs
            WHERE lead_id = %s
            ORDER BY design_order
            LIMIT 1
        """, (lead_id,))
        first_design = cur.fetchone()
        
        # Get next order
        cur.execute("SELECT COALESCE(MAX(design_order), 0) + 1 as next_order FROM lead_designs WHERE lead_id = %s", (lead_id,))
        result = cur.fetchone()
        next_order = result['next_order'] if result else 1
        
        if first_design:
            # Copy ALL properties from first design (all 17 items with quantities and prices)
            cur.execute("""
                INSERT INTO lead_designs (
                    lead_id, design_name, design_image, design_order, media_files,
                    has_table, table_quantity, table_price, table_details,
                    has_chair, chair_quantity, chair_price, chair_details,
                    has_plants, plants_quantity, plants_price, plants_details,
                    has_lighting, lighting_quantity, lighting_price, lighting_details,
                    has_profile_lighting, profile_lighting_quantity, profile_lighting_price, profile_lighting_details,
                    has_storage, storage_quantity, storage_price, storage_details,
                    has_accessories, accessories_quantity, accessories_price, accessories_details,
                    has_big_plants, big_plants_quantity, big_plants_price, big_plants_details,
                    has_mini_plants, mini_plants_quantity, mini_plants_price, mini_plants_details,
                    has_frames, frames_quantity, frames_price, frames_details,
                    has_wall_racks, wall_racks_quantity, wall_racks_price, wall_racks_details,
                    has_desk_mat, desk_mat_quantity, desk_mat_price, desk_mat_details,
                    has_dustbin, dustbin_quantity, dustbin_price, dustbin_details,
                    has_floor_mat, floor_mat_quantity, floor_mat_price, floor_mat_details,
                    has_keyboard, keyboard_quantity, keyboard_price, keyboard_details,
                    has_mouse, mouse_quantity, mouse_price, mouse_details,
                    has_paint, paint_quantity, paint_price, paint_details,
                    has_wardrobes, wardrobes_quantity, wardrobes_price, wardrobes_details,
                    price, notes
                )
                VALUES (%s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                lead_id, design_name, design_image, next_order, json.dumps(media_files),
                first_design.get('has_table', False), first_design.get('table_quantity', 1), first_design.get('table_price', 0), first_design.get('table_details', ''),
                first_design.get('has_chair', False), first_design.get('chair_quantity', 1), first_design.get('chair_price', 0), first_design.get('chair_details', ''),
                first_design.get('has_plants', False), first_design.get('plants_quantity', 1), first_design.get('plants_price', 0), first_design.get('plants_details', ''),
                first_design.get('has_lighting', False), first_design.get('lighting_quantity', 1), first_design.get('lighting_price', 0), first_design.get('lighting_details', ''),
                first_design.get('has_profile_lighting', False), first_design.get('profile_lighting_quantity', 1), first_design.get('profile_lighting_price', 0), first_design.get('profile_lighting_details', ''),
                first_design.get('has_storage', False), first_design.get('storage_quantity', 1), first_design.get('storage_price', 0), first_design.get('storage_details', ''),
                first_design.get('has_accessories', False), first_design.get('accessories_quantity', 1), first_design.get('accessories_price', 0), first_design.get('accessories_details', ''),
                first_design.get('has_big_plants', False), first_design.get('big_plants_quantity', 1), first_design.get('big_plants_price', 0), first_design.get('big_plants_details', ''),
                first_design.get('has_mini_plants', False), first_design.get('mini_plants_quantity', 1), first_design.get('mini_plants_price', 0), first_design.get('mini_plants_details', ''),
                first_design.get('has_frames', False), first_design.get('frames_quantity', 1), first_design.get('frames_price', 0), first_design.get('frames_details', ''),
                first_design.get('has_wall_racks', False), first_design.get('wall_racks_quantity', 1), first_design.get('wall_racks_price', 0), first_design.get('wall_racks_details', ''),
                first_design.get('has_desk_mat', False), first_design.get('desk_mat_quantity', 1), first_design.get('desk_mat_price', 0), first_design.get('desk_mat_details', ''),
                first_design.get('has_dustbin', False), first_design.get('dustbin_quantity', 1), first_design.get('dustbin_price', 0), first_design.get('dustbin_details', ''),
                first_design.get('has_floor_mat', False), first_design.get('floor_mat_quantity', 1), first_design.get('floor_mat_price', 0), first_design.get('floor_mat_details', ''),
                first_design.get('has_keyboard', False), first_design.get('keyboard_quantity', 1), first_design.get('keyboard_price', 0), first_design.get('keyboard_details', ''),
                first_design.get('has_mouse', False), first_design.get('mouse_quantity', 1), first_design.get('mouse_price', 0), first_design.get('mouse_details', ''),
                first_design.get('has_paint', False), first_design.get('paint_quantity', 1), first_design.get('paint_price', 0), first_design.get('paint_details', ''),
                first_design.get('has_wardrobes', False), first_design.get('wardrobes_quantity', 1), first_design.get('wardrobes_price', 0), first_design.get('wardrobes_details', ''),
                first_design.get('price', 0), first_design.get('notes', '')
            ))
            flash('Design added! All items, quantities, and prices copied from first design. You can now customize it.', 'success')
        else:
            # First design - create with defaults
            cur.execute("""
                INSERT INTO lead_designs (lead_id, design_name, design_image, design_order, media_files)
                VALUES (%s, %s, %s, %s, %s)
            """, (lead_id, design_name, design_image, next_order, json.dumps(media_files)))
            flash('First design added! Set up the items and price.', 'info')
        
        conn.commit()
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_details = traceback.format_exc()
        print(f"ERROR in add_design: {error_details}")
        flash(f'Error adding design: {str(e)}', 'danger')
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
        notes = request.form.get('notes', '')
        
        # Define all 17 items
        items = [
            'table', 'chair', 'plants', 'lighting', 'storage', 'accessories',
            'big_plants', 'mini_plants', 'frames', 'wall_racks', 'desk_mat',
            'dustbin', 'floor_mat', 'keyboard', 'mouse', 'paint', 'wardrobes'
        ]
        
        # Collect data for all items
        item_data = {}
        subtotal = 0
        
        for item in items:
            has_item = request.form.get(f'has_{item}') == 'on'
            
            # Handle empty strings for quantity and price
            quantity_str = request.form.get(f'{item}_quantity', '1')
            quantity = int(quantity_str) if quantity_str and quantity_str.strip() else 1
            
            price_str = request.form.get(f'{item}_price', '0')
            price = float(price_str) if price_str and price_str.strip() else 0.0
            
            details = request.form.get(f'{item}_details', '')
            
            item_data[item] = {
                'has': has_item,
                'quantity': quantity,
                'price': price,
                'details': details
            }
            
            # Calculate subtotal: quantity × price for each item
            if has_item:
                subtotal += quantity * price
        
        # Handle custom items with prices and quantities
        custom_items = []
        names = request.form.getlist('custom_item_name[]')
        details_list = request.form.getlist('custom_item_details[]')
        icons = request.form.getlist('custom_item_icon[]')
        prices = request.form.getlist('custom_item_price[]')
        quantities = request.form.getlist('custom_item_quantity[]')
        
        for i in range(len(names)):
            if names[i].strip():
                # Handle empty strings for quantity and price
                qty_str = quantities[i] if i < len(quantities) else '1'
                qty = int(qty_str) if qty_str and qty_str.strip() else 1
                
                price_str = prices[i] if i < len(prices) else '0'
                price = float(price_str) if price_str and price_str.strip() else 0.0
                custom_items.append({
                    'name': names[i],
                    'details': details_list[i] if i < len(details_list) else '',
                    'icon': icons[i] if i < len(icons) else '📌',
                    'price': price,
                    'quantity': qty
                })
                # Add to subtotal
                subtotal += qty * price
        
        # Get discount info
        discount_type = request.form.get('discount_type', 'none')
        discount_value = float(request.form.get('discount_value', 0))
        
        # Calculate final price
        final_price = subtotal
        if discount_type == 'percentage':
            final_price = subtotal - (subtotal * discount_value / 100)
        elif discount_type == 'fixed':
            final_price = subtotal - discount_value
        final_price = max(0, final_price)  # Ensure non-negative
        
        # Build UPDATE query with all 17 items
        cur.execute("""
            UPDATE lead_designs
            SET design_name = %s,
                has_table = %s, table_quantity = %s, table_price = %s, table_details = %s,
                has_chair = %s, chair_quantity = %s, chair_price = %s, chair_details = %s,
                has_plants = %s, plants_quantity = %s, plants_price = %s, plants_details = %s,
                has_lighting = %s, lighting_quantity = %s, lighting_price = %s, lighting_details = %s,
                has_storage = %s, storage_quantity = %s, storage_price = %s, storage_details = %s,
                has_accessories = %s, accessories_quantity = %s, accessories_price = %s, accessories_details = %s,
                has_big_plants = %s, big_plants_quantity = %s, big_plants_price = %s, big_plants_details = %s,
                has_mini_plants = %s, mini_plants_quantity = %s, mini_plants_price = %s, mini_plants_details = %s,
                has_frames = %s, frames_quantity = %s, frames_price = %s, frames_details = %s,
                has_wall_racks = %s, wall_racks_quantity = %s, wall_racks_price = %s, wall_racks_details = %s,
                has_desk_mat = %s, desk_mat_quantity = %s, desk_mat_price = %s, desk_mat_details = %s,
                has_dustbin = %s, dustbin_quantity = %s, dustbin_price = %s, dustbin_details = %s,
                has_floor_mat = %s, floor_mat_quantity = %s, floor_mat_price = %s, floor_mat_details = %s,
                has_keyboard = %s, keyboard_quantity = %s, keyboard_price = %s, keyboard_details = %s,
                has_mouse = %s, mouse_quantity = %s, mouse_price = %s, mouse_details = %s,
                has_paint = %s, paint_quantity = %s, paint_price = %s, paint_details = %s,
                has_wardrobes = %s, wardrobes_quantity = %s, wardrobes_price = %s, wardrobes_details = %s,
                subtotal = %s, discount_type = %s, discount_value = %s,
                final_price = %s, price = %s, notes = %s, custom_items = %s
            WHERE id = %s
        """, (
            design_name,
            # Table
            item_data['table']['has'], item_data['table']['quantity'], item_data['table']['price'], item_data['table']['details'],
            # Chair
            item_data['chair']['has'], item_data['chair']['quantity'], item_data['chair']['price'], item_data['chair']['details'],
            # Plants
            item_data['plants']['has'], item_data['plants']['quantity'], item_data['plants']['price'], item_data['plants']['details'],
            # Lighting
            item_data['lighting']['has'], item_data['lighting']['quantity'], item_data['lighting']['price'], item_data['lighting']['details'],
            # Storage
            item_data['storage']['has'], item_data['storage']['quantity'], item_data['storage']['price'], item_data['storage']['details'],
            # Accessories
            item_data['accessories']['has'], item_data['accessories']['quantity'], item_data['accessories']['price'], item_data['accessories']['details'],
            # Big Plants
            item_data['big_plants']['has'], item_data['big_plants']['quantity'], item_data['big_plants']['price'], item_data['big_plants']['details'],
            # Mini Plants
            item_data['mini_plants']['has'], item_data['mini_plants']['quantity'], item_data['mini_plants']['price'], item_data['mini_plants']['details'],
            # Frames
            item_data['frames']['has'], item_data['frames']['quantity'], item_data['frames']['price'], item_data['frames']['details'],
            # Wall Racks
            item_data['wall_racks']['has'], item_data['wall_racks']['quantity'], item_data['wall_racks']['price'], item_data['wall_racks']['details'],
            # Desk Mat
            item_data['desk_mat']['has'], item_data['desk_mat']['quantity'], item_data['desk_mat']['price'], item_data['desk_mat']['details'],
            # Dustbin
            item_data['dustbin']['has'], item_data['dustbin']['quantity'], item_data['dustbin']['price'], item_data['dustbin']['details'],
            # Floor Mat
            item_data['floor_mat']['has'], item_data['floor_mat']['quantity'], item_data['floor_mat']['price'], item_data['floor_mat']['details'],
            # Keyboard
            item_data['keyboard']['has'], item_data['keyboard']['quantity'], item_data['keyboard']['price'], item_data['keyboard']['details'],
            # Mouse
            item_data['mouse']['has'], item_data['mouse']['quantity'], item_data['mouse']['price'], item_data['mouse']['details'],
            # Paint
            item_data['paint']['has'], item_data['paint']['quantity'], item_data['paint']['price'], item_data['paint']['details'],
            # Wardrobes
            item_data['wardrobes']['has'], item_data['wardrobes']['quantity'], item_data['wardrobes']['price'], item_data['wardrobes']['details'],
            # Pricing
            subtotal, discount_type, discount_value, final_price, final_price, notes,
            json.dumps(custom_items), design_id
        ))
        
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

@leads_bp.route('/admin/leads/<int:lead_id>/delete', methods=['POST'])
@admin_required
def delete_lead(lead_id):
    """Delete entire lead and all its designs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Delete all designs first (foreign key constraint)
        cur.execute("DELETE FROM lead_designs WHERE lead_id = %s", (lead_id,))
        
        # Delete the lead
        cur.execute("DELETE FROM leads WHERE id = %s", (lead_id,))
        
        conn.commit()
        flash('Lead and all its designs deleted successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error deleting lead: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.admin_leads_list'))

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
    
    # Parse custom_items and media_files JSON for each design
    for design in designs:
        # Parse custom_items
        if design.get('custom_items'):
            try:
                design['custom_items'] = json.loads(design['custom_items'])
            except:
                design['custom_items'] = []
        else:
            design['custom_items'] = []
        
        # Parse media_files
        if design.get('media_files'):
            try:
                design['media_files'] = json.loads(design['media_files'])
            except:
                design['media_files'] = []
        else:
            design['media_files'] = []
        
        # Fallback: if no media_files but has design_image, create media_files array
        if not design['media_files'] and design.get('design_image'):
            design['media_files'] = [{
                'type': 'image',
                'url': design['design_image'],
                'order': 0
            }]
    
    # Calculate total
    total = sum(d['price'] or 0 for d in designs)
    
    cur.close()
    conn.close()
    
    return render_template('quotation_view_simple.html',
                         lead=lead, designs=designs, total=total)

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
    return render_template('admin_default_prices.html', items=items)

def register_leads_routes(app, db_connection_func):
    """Register blueprint with app"""
    global get_db_connection
    get_db_connection = db_connection_func
    app.register_blueprint(leads_bp)

# Made with Bob
