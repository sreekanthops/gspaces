"""
Simplified Leads/Quotation System - MVP Version
Admin creates leads with designs and manual pricing
"""

import os
import secrets
import json
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, render_template_string
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
               MIN(ld.price) as min_price,
               MAX(ld.price) as max_price,
               lc.comment as latest_comment,
               lc.created_at as latest_comment_date
        FROM leads l
        LEFT JOIN lead_designs ld ON l.id = ld.lead_id
        LEFT JOIN LATERAL (
            SELECT comment, created_at
            FROM lead_comments
            WHERE lead_id = l.id
            ORDER BY created_at DESC
            LIMIT 1
        ) lc ON true
        GROUP BY l.id, lc.comment, lc.created_at
        ORDER BY COALESCE(l.is_priority, FALSE) DESC, l.created_at DESC
    """)
    leads = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('admin_leads_simple.html', leads=leads)

@leads_bp.route('/admin/leads/<int:lead_id>/toggle-priority', methods=['POST'])
@login_required
@admin_required
def toggle_lead_priority(lead_id):
    """Toggle priority status of a lead"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Toggle the priority
        cur.execute("""
            UPDATE leads
            SET is_priority = NOT COALESCE(is_priority, FALSE)
            WHERE id = %s
            RETURNING is_priority
        """, (lead_id,))
        
        result = cur.fetchone()
        conn.commit()
        
        return jsonify({
            'success': True,
            'is_priority': result['is_priority'] if result else False
        })
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@leads_bp.route('/admin/leads/<int:lead_id>/comments', methods=['GET'])
@login_required
@admin_required
def get_lead_comments(lead_id):
    """Get all comments for a lead"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("""
            SELECT lc.*, u.name as created_by_name
            FROM lead_comments lc
            LEFT JOIN users u ON lc.created_by = u.id
            WHERE lc.lead_id = %s
            ORDER BY lc.created_at DESC
        """, (lead_id,))
        
        comments = cur.fetchall()
        
        return jsonify({
            'success': True,
            'comments': [dict(c) for c in comments]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@leads_bp.route('/admin/leads/<int:lead_id>/comments', methods=['POST'])
@login_required
@admin_required
def add_lead_comment(lead_id):
    """Add a comment to a lead"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        comment_text = request.json.get('comment', '').strip()
        
        if not comment_text:
            return jsonify({'success': False, 'error': 'Comment cannot be empty'}), 400
        
        cur.execute("""
            INSERT INTO lead_comments (lead_id, comment, created_by)
            VALUES (%s, %s, %s)
            RETURNING id, comment, created_at
        """, (lead_id, comment_text, current_user.id))
        
        new_comment = cur.fetchone()
        conn.commit()
        
        return jsonify({
            'success': True,
            'comment': {
                'id': new_comment['id'],
                'comment': new_comment['comment'],
                'created_at': new_comment['created_at'].isoformat(),
                'created_by_name': current_user.name
            }
        })
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@leads_bp.route('/admin/leads/comments/<int:comment_id>', methods=['DELETE'])
@login_required
@admin_required
def delete_lead_comment(comment_id):
    """Delete a comment"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("""
            DELETE FROM lead_comments
            WHERE id = %s
            RETURNING id
        """, (comment_id,))
        
        deleted = cur.fetchone()
        conn.commit()
        
        if deleted:
            return jsonify({'success': True})
        else:
            return jsonify({'success': False, 'error': 'Comment not found'}), 404
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@leads_bp.route('/admin/leads/create', methods=['GET', 'POST'])
@admin_required
def create_lead():
    """Create new lead"""
    if request.method == 'POST':
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            customer_name = request.form.get('customer_name')
            customer_email = request.form.get('customer_email', '').strip()
            customer_phone = request.form.get('customer_phone', '')
            project_name = request.form.get('project_name', '')
            location = request.form.get('location', '').strip()
            notes = request.form.get('notes', '').strip() or 'Transform your space into a dream workspace setup.'
            setup_type = request.form.get('setup_type', '').strip()
            space_size = request.form.get('space_size', '').strip()
            customer_type = request.form.get('customer_type', 'genuine')
            
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
                                 project_name, location, reference_image, notes, share_token, created_by,
                                 setup_type, space_size, customer_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (customer_name, customer_email, customer_phone, project_name,
                  location, reference_image, notes, share_token, current_user.id,
                  setup_type, space_size, customer_type))
            
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
            customer_email = request.form.get('customer_email', '').strip()
            customer_phone = request.form.get('customer_phone', '')
            project_name = request.form.get('project_name', '')
            location = request.form.get('location', '').strip()
            notes = request.form.get('notes', '').strip()
            customer_type = request.form.get('customer_type', 'Genuine')
            setup_type = request.form.get('setup_type', '').strip()
            space_size = request.form.get('space_size', '').strip()
            
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
                    project_name = %s, location = %s, notes = %s, reference_image = %s,
                    customer_type = %s, setup_type = %s, space_size = %s
                WHERE id = %s
            """, (customer_name, customer_email, customer_phone, project_name,
                  location, notes, reference_image, customer_type, setup_type, space_size, lead_id))
            
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
        # Parse custom_items - handle both JSONB (already parsed) and TEXT (needs parsing)
        if design.get('custom_items'):
            if isinstance(design['custom_items'], list):
                # Already parsed (JSONB column)
                pass
            elif isinstance(design['custom_items'], str):
                # String that needs parsing (TEXT column)
                try:
                    design['custom_items'] = json.loads(design['custom_items'])
                except:
                    design['custom_items'] = []
            else:
                design['custom_items'] = []
        else:
            design['custom_items'] = []
        
        # Parse media_files (JSONB is already parsed by psycopg2)
        if design.get('media_files'):
            # If it's already a list (JSONB), use it directly
            if isinstance(design['media_files'], list):
                pass  # Already parsed
            elif isinstance(design['media_files'], str):
                # If it's a string, parse it
                try:
                    design['media_files'] = json.loads(design['media_files'])
                except:
                    design['media_files'] = []
        else:
            design['media_files'] = []
    
    # Fetch default items with icons and prices from database
    cur.execute("""
        SELECT id, item_name, item_slug, icon_emoji, icon_image, default_price, description,
               has_length, has_breadth, has_height, display_order, is_active
        FROM default_items
        WHERE is_active = TRUE
        ORDER BY display_order, item_name
    """)
    default_items_list = cur.fetchall()
    
    # Create a dictionary for backward compatibility with default_prices
    default_prices = {row['item_slug']: row['default_price'] for row in default_items_list}
    
    # Also pass the full items list for icon display
    default_items = [dict(row) for row in default_items_list]
    
    cur.close()
    conn.close()
    
    return render_template('edit_lead_simple.html', lead=lead, designs=designs,
                          default_prices=default_prices, default_items=default_items)

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
        
        # Get first design to copy properties from (updated items list)
        cur.execute("""
            SELECT has_table, table_quantity, table_price, table_details,
                   table_length_ft, table_width_ft, table_height_inch,
                   has_chair, chair_quantity, chair_price, chair_details, chair_headrest,
                   has_lighting, lighting_quantity, lighting_price, lighting_details, lighting_length_ft,
                   has_profile_lighting, profile_lighting_quantity, profile_lighting_price, profile_lighting_details, profile_lighting_length_ft,
                   has_storage, storage_quantity, storage_price, storage_details,
                   storage_length_ft, storage_width_ft, storage_height_ft,
                   has_big_plants, big_plants_quantity, big_plants_price, big_plants_details, big_plants_height_ft,
                   has_mini_plants, mini_plants_quantity, mini_plants_price, mini_plants_details, mini_plants_height_ft,
                   has_frames, frames_quantity, frames_price, frames_details, frames_size_ft,
                   has_wall_racks, wall_racks_quantity, wall_racks_price, wall_racks_details, wall_racks_length_ft,
                   has_dustbin, dustbin_quantity, dustbin_price, dustbin_details,
                   has_paint, paint_quantity, paint_price, paint_details,
                   has_wardrobes, wardrobes_quantity, wardrobes_price, wardrobes_details,
                   has_multi_socket, multi_socket_quantity, multi_socket_price, multi_socket_details,
                   has_desk_lamp, desk_lamp_quantity, desk_lamp_price, desk_lamp_details,
                   has_pen_holder, pen_holder_quantity, pen_holder_price, pen_holder_details,
                   has_laptop_holder, laptop_holder_quantity, laptop_holder_price, laptop_holder_details,
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
            # Copy ALL properties from first design (updated items with dimensions)
            cur.execute("""
                INSERT INTO lead_designs (
                    lead_id, design_name, design_image, design_order, media_files,
                    has_table, table_quantity, table_price, table_details,
                    table_length_ft, table_width_ft, table_height_inch,
                    has_chair, chair_quantity, chair_price, chair_details, chair_headrest,
                    has_lighting, lighting_quantity, lighting_price, lighting_details, lighting_length_ft,
                    has_profile_lighting, profile_lighting_quantity, profile_lighting_price, profile_lighting_details, profile_lighting_length_ft,
                    has_storage, storage_quantity, storage_price, storage_details,
                    storage_length_ft, storage_width_ft, storage_height_ft,
                    has_big_plants, big_plants_quantity, big_plants_price, big_plants_details, big_plants_height_ft,
                    has_mini_plants, mini_plants_quantity, mini_plants_price, mini_plants_details, mini_plants_height_ft,
                    has_frames, frames_quantity, frames_price, frames_details, frames_size_ft,
                    has_wall_racks, wall_racks_quantity, wall_racks_price, wall_racks_details, wall_racks_length_ft,
                    has_dustbin, dustbin_quantity, dustbin_price, dustbin_details,
                    has_paint, paint_quantity, paint_price, paint_details,
                    has_wardrobes, wardrobes_quantity, wardrobes_price, wardrobes_details,
                    has_multi_socket, multi_socket_quantity, multi_socket_price, multi_socket_details,
                    has_desk_lamp, desk_lamp_quantity, desk_lamp_price, desk_lamp_details,
                    has_pen_holder, pen_holder_quantity, pen_holder_price, pen_holder_details,
                    has_laptop_holder, laptop_holder_quantity, laptop_holder_price, laptop_holder_details,
                    price, notes
                )
                VALUES (%s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s)
            """, (
                lead_id, design_name, design_image, next_order, json.dumps(media_files),
                # Table + dimensions
                first_design.get('has_table', False), first_design.get('table_quantity', 1), first_design.get('table_price', 0), first_design.get('table_details', ''),
                first_design.get('table_length_ft', 4), first_design.get('table_width_ft', 2), first_design.get('table_height_inch', 29),
                # Chair + headrest
                first_design.get('has_chair', False), first_design.get('chair_quantity', 1), first_design.get('chair_price', 0), first_design.get('chair_details', ''), first_design.get('chair_headrest', 'with_headrest'),
                # Lighting + length
                first_design.get('has_lighting', False), first_design.get('lighting_quantity', 1), first_design.get('lighting_price', 0), first_design.get('lighting_details', ''), first_design.get('lighting_length_ft', 10),
                # Profile Lighting + length
                first_design.get('has_profile_lighting', False), first_design.get('profile_lighting_quantity', 1), first_design.get('profile_lighting_price', 0), first_design.get('profile_lighting_details', ''), first_design.get('profile_lighting_length_ft', 10),
                # Storage + dimensions
                first_design.get('has_storage', False), first_design.get('storage_quantity', 1), first_design.get('storage_price', 0), first_design.get('storage_details', ''),
                first_design.get('storage_length_ft', 3), first_design.get('storage_width_ft', 1.5), first_design.get('storage_height_ft', 6),
                # Big Plants + height
                first_design.get('has_big_plants', False), first_design.get('big_plants_quantity', 1), first_design.get('big_plants_price', 0), first_design.get('big_plants_details', ''), first_design.get('big_plants_height_ft', 3),
                # Mini Plants + height
                first_design.get('has_mini_plants', False), first_design.get('mini_plants_quantity', 1), first_design.get('mini_plants_price', 0), first_design.get('mini_plants_details', ''), first_design.get('mini_plants_height_ft', 1),
                # Frames + size
                first_design.get('has_frames', False), first_design.get('frames_quantity', 1), first_design.get('frames_price', 0), first_design.get('frames_details', ''), first_design.get('frames_size_ft', '2x3'),
                # Wall Racks + length
                first_design.get('has_wall_racks', False), first_design.get('wall_racks_quantity', 1), first_design.get('wall_racks_price', 0), first_design.get('wall_racks_details', ''), first_design.get('wall_racks_length_ft', 4),
                # Dustbin
                first_design.get('has_dustbin', False), first_design.get('dustbin_quantity', 1), first_design.get('dustbin_price', 0), first_design.get('dustbin_details', ''),
                # Paint
                first_design.get('has_paint', False), first_design.get('paint_quantity', 1), first_design.get('paint_price', 0), first_design.get('paint_details', ''),
                # Wardrobes
                first_design.get('has_wardrobes', False), first_design.get('wardrobes_quantity', 1), first_design.get('wardrobes_price', 0), first_design.get('wardrobes_details', ''),
                # Multi Socket
                first_design.get('has_multi_socket', False), first_design.get('multi_socket_quantity', 1), first_design.get('multi_socket_price', 0), first_design.get('multi_socket_details', ''),
                # Desk Lamp
                first_design.get('has_desk_lamp', False), first_design.get('desk_lamp_quantity', 1), first_design.get('desk_lamp_price', 0), first_design.get('desk_lamp_details', ''),
                # Pen Holder
                first_design.get('has_pen_holder', False), first_design.get('pen_holder_quantity', 1), first_design.get('pen_holder_price', 0), first_design.get('pen_holder_details', ''),
                # Laptop Holder
                first_design.get('has_laptop_holder', False), first_design.get('laptop_holder_quantity', 1), first_design.get('laptop_holder_price', 0), first_design.get('laptop_holder_details', ''),
                # Pricing
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
        
        # Define all supported items
        items = [
            'table', 'chair', 'lighting', 'profile_lighting', 'storage',
            'big_plants', 'mini_plants', 'frames', 'wall_racks',
            'dustbin', 'paint', 'wardrobes', 'desk_mat', 'multi_socket',
            'desk_lamp', 'pen_holder', 'laptop_holder'
        ]
        
        # Collect data for all items
        item_data = {}
        subtotal = 0
        
        # Get dimension fields
        table_length_ft = float(request.form.get('table_length_ft', 4))
        table_width_ft = float(request.form.get('table_width_ft', 2))
        table_height_inch = float(request.form.get('table_height_inch', 29))
        
        storage_length_ft = float(request.form.get('storage_length_ft', 3))
        storage_width_ft = float(request.form.get('storage_width_ft', 1.5))
        storage_height_ft = float(request.form.get('storage_height_ft', 6))
        
        lighting_length_ft = float(request.form.get('lighting_length_ft', 10))
        profile_lighting_length_ft = float(request.form.get('profile_lighting_length_ft', 10))
        
        frames_size_ft = request.form.get('frames_size_ft', '2x3')
        wall_racks_length_ft = float(request.form.get('wall_racks_length_ft', 4))
        
        # Plant height fields
        big_plants_height_ft = float(request.form.get('big_plants_height_ft', 3))
        mini_plants_height_ft = float(request.form.get('mini_plants_height_ft', 1))
        
        # Wardrobe dimensions
        wardrobes_length_ft = float(request.form.get('wardrobes_length_ft', 6))
        wardrobes_width_ft = float(request.form.get('wardrobes_width_ft', 2))
        wardrobes_height_ft = float(request.form.get('wardrobes_height_ft', 7))
        
        desk_mat_length = request.form.get('desk_mat_length', '').strip()
        desk_mat_height = request.form.get('desk_mat_height', '').strip()
        chair_headrest = request.form.get('chair_headrest', 'with_headrest')
        
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
            
            # Calculate subtotal: quantity × price for each item (except table and wardrobes)
            if has_item:
                if item == 'table':
                    # For table: area (length × width) × price per sq ft
                    area = table_length_ft * table_width_ft
                    subtotal += area * price
                elif item == 'wardrobes':
                    # For wardrobes: area (length × width) × price per sq ft
                    area = wardrobes_length_ft * wardrobes_width_ft
                    subtotal += area * price
                elif item == 'desk_mat':
                    subtotal += quantity * price
                else:
                    # Normal items: quantity × price
                    subtotal += quantity * price
        
        # Handle custom items with prices and quantities
        custom_items = []
        names = request.form.getlist('custom_item_name[]')
        details_list = request.form.getlist('custom_item_details[]')
        icons = request.form.getlist('custom_item_icon[]')
        prices = request.form.getlist('custom_item_price[]')
        quantities = request.form.getlist('custom_item_quantity[]')
        lengths = request.form.getlist('custom_item_length[]')
        breadths = request.form.getlist('custom_item_breadth[]')
        heights = request.form.getlist('custom_item_height[]')
        item_slugs = request.form.getlist('custom_item_slug[]')
        has_lengths = request.form.getlist('custom_item_has_length[]')
        has_breadths = request.form.getlist('custom_item_has_breadth[]')
        has_heights = request.form.getlist('custom_item_has_height[]')
        
        for i in range(len(names)):
            if names[i].strip():
                # Handle empty strings for quantity and price
                qty_str = quantities[i] if i < len(quantities) else '1'
                qty = int(qty_str) if qty_str and qty_str.strip() else 1
                
                price_str = prices[i] if i < len(prices) else '0'
                price = float(price_str) if price_str and price_str.strip() else 0.0
                length_value = lengths[i].strip() if i < len(lengths) and lengths[i] else ''
                breadth_value = breadths[i].strip() if i < len(breadths) and breadths[i] else ''
                height_value = heights[i].strip() if i < len(heights) and heights[i] else ''
                has_length = i < len(has_lengths) and has_lengths[i] == 'true'
                has_breadth = i < len(has_breadths) and has_breadths[i] == 'true'
                has_height = i < len(has_heights) and has_heights[i] == 'true'

                custom_items.append({
                    'name': names[i],
                    'slug': item_slugs[i] if i < len(item_slugs) else '',
                    'details': details_list[i] if i < len(details_list) else '',
                    'icon': icons[i] if i < len(icons) else '📌',
                    'price': price,
                    'quantity': qty,
                    'has_length': has_length,
                    'has_breadth': has_breadth,
                    'has_height': has_height,
                    'length': length_value,
                    'breadth': breadth_value,
                    'height': height_value
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
        
        # Build UPDATE query with updated items + dimensions
        cur.execute("""
            UPDATE lead_designs
            SET design_name = %s,
                has_table = %s, table_quantity = %s, table_price = %s, table_details = %s,
                table_length_ft = %s, table_width_ft = %s, table_height_inch = %s,
                has_chair = %s, chair_quantity = %s, chair_price = %s, chair_details = %s, chair_headrest = %s,
                has_lighting = %s, lighting_quantity = %s, lighting_price = %s, lighting_details = %s, lighting_length_ft = %s,
                has_profile_lighting = %s, profile_lighting_quantity = %s, profile_lighting_price = %s, profile_lighting_details = %s, profile_lighting_length_ft = %s,
                has_storage = %s, storage_quantity = %s, storage_price = %s, storage_details = %s,
                storage_length_ft = %s, storage_width_ft = %s, storage_height_ft = %s,
                has_big_plants = %s, big_plants_quantity = %s, big_plants_price = %s, big_plants_details = %s, big_plants_height_ft = %s,
                has_mini_plants = %s, mini_plants_quantity = %s, mini_plants_price = %s, mini_plants_details = %s, mini_plants_height_ft = %s,
                has_frames = %s, frames_quantity = %s, frames_price = %s, frames_details = %s, frames_size_ft = %s,
                has_wall_racks = %s, wall_racks_quantity = %s, wall_racks_price = %s, wall_racks_details = %s, wall_racks_length_ft = %s,
                has_dustbin = %s, dustbin_quantity = %s, dustbin_price = %s, dustbin_details = %s,
                has_paint = %s, paint_quantity = %s, paint_price = %s, paint_details = %s,
                has_wardrobes = %s, wardrobes_quantity = %s, wardrobes_price = %s, wardrobes_details = %s,
                wardrobes_length_ft = %s, wardrobes_width_ft = %s, wardrobes_height_ft = %s,
                has_desk_mat = %s, desk_mat_quantity = %s, desk_mat_price = %s, desk_mat_details = %s,
                desk_mat_length = %s, desk_mat_height = %s,
                has_multi_socket = %s, multi_socket_quantity = %s, multi_socket_price = %s, multi_socket_details = %s,
                has_desk_lamp = %s, desk_lamp_quantity = %s, desk_lamp_price = %s, desk_lamp_details = %s,
                has_pen_holder = %s, pen_holder_quantity = %s, pen_holder_price = %s, pen_holder_details = %s,
                has_laptop_holder = %s, laptop_holder_quantity = %s, laptop_holder_price = %s, laptop_holder_details = %s,
                subtotal = %s, discount_type = %s, discount_value = %s,
                final_price = %s, price = %s, notes = %s, custom_items = %s
            WHERE id = %s
        """, (
            design_name,
            # Table + dimensions
            item_data['table']['has'], item_data['table']['quantity'], item_data['table']['price'], item_data['table']['details'],
            table_length_ft, table_width_ft, table_height_inch,
            # Chair + headrest
            item_data['chair']['has'], item_data['chair']['quantity'], item_data['chair']['price'], item_data['chair']['details'], chair_headrest,
            # Lighting + length
            item_data['lighting']['has'], item_data['lighting']['quantity'], item_data['lighting']['price'], item_data['lighting']['details'], lighting_length_ft,
            # Profile Lighting + length
            item_data['profile_lighting']['has'], item_data['profile_lighting']['quantity'], item_data['profile_lighting']['price'], item_data['profile_lighting']['details'], profile_lighting_length_ft,
            # Storage + dimensions
            item_data['storage']['has'], item_data['storage']['quantity'], item_data['storage']['price'], item_data['storage']['details'],
            storage_length_ft, storage_width_ft, storage_height_ft,
            # Big Plants + height
            item_data['big_plants']['has'], item_data['big_plants']['quantity'], item_data['big_plants']['price'], item_data['big_plants']['details'], big_plants_height_ft,
            # Mini Plants + height
            item_data['mini_plants']['has'], item_data['mini_plants']['quantity'], item_data['mini_plants']['price'], item_data['mini_plants']['details'], mini_plants_height_ft,
            # Frames + size
            item_data['frames']['has'], item_data['frames']['quantity'], item_data['frames']['price'], item_data['frames']['details'], frames_size_ft,
            # Wall Racks + length
            item_data['wall_racks']['has'], item_data['wall_racks']['quantity'], item_data['wall_racks']['price'], item_data['wall_racks']['details'], wall_racks_length_ft,
            # Dustbin
            item_data['dustbin']['has'], item_data['dustbin']['quantity'], item_data['dustbin']['price'], item_data['dustbin']['details'],
            # Paint
            item_data['paint']['has'], item_data['paint']['quantity'], item_data['paint']['price'], item_data['paint']['details'],
            # Wardrobes + dimensions
            item_data['wardrobes']['has'], item_data['wardrobes']['quantity'], item_data['wardrobes']['price'], item_data['wardrobes']['details'],
            wardrobes_length_ft, wardrobes_width_ft, wardrobes_height_ft,
            # Desk Mat
            item_data['desk_mat']['has'], item_data['desk_mat']['quantity'], item_data['desk_mat']['price'], item_data['desk_mat']['details'],
            desk_mat_length, desk_mat_height,
            # Multi Socket
            item_data['multi_socket']['has'], item_data['multi_socket']['quantity'], item_data['multi_socket']['price'], item_data['multi_socket']['details'],
            # Desk Lamp
            item_data['desk_lamp']['has'], item_data['desk_lamp']['quantity'], item_data['desk_lamp']['price'], item_data['desk_lamp']['details'],
            # Pen Holder
            item_data['pen_holder']['has'], item_data['pen_holder']['quantity'], item_data['pen_holder']['price'], item_data['pen_holder']['details'],
            # Laptop Holder
            item_data['laptop_holder']['has'], item_data['laptop_holder']['quantity'], item_data['laptop_holder']['price'], item_data['laptop_holder']['details'],
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
    
    # Get lead with expiry info
    cur.execute("""
        SELECT *,
               CASE WHEN valid_until IS NOT NULL AND valid_until < CURRENT_TIMESTAMP
                    THEN TRUE ELSE is_expired END as is_expired
        FROM leads
        WHERE share_token = %s
    """, (share_token,))
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
        # Parse custom_items - handle both JSONB (already parsed) and TEXT (needs parsing)
        if design.get('custom_items'):
            if isinstance(design['custom_items'], list):
                # Already parsed (JSONB column)
                pass
            elif isinstance(design['custom_items'], str):
                # String that needs parsing (TEXT column)
                try:
                    design['custom_items'] = json.loads(design['custom_items'])
                except:
                    design['custom_items'] = []
            else:
                design['custom_items'] = []
        else:
            design['custom_items'] = []
        
        # Parse media_files (JSONB is already parsed by psycopg2)
        if design.get('media_files'):
            # If it's already a list (JSONB), use it directly
            if isinstance(design['media_files'], list):
                pass  # Already parsed
            elif isinstance(design['media_files'], str):
                # If it's a string, parse it
                try:
                    design['media_files'] = json.loads(design['media_files'])
                except:
                    design['media_files'] = []
        else:
            design['media_files'] = []
        
        # Combine design_image with media_files for carousel
        # Prefer media_files and only use legacy design_image as fallback.
        all_media = []

        media_urls = set()
        for media in design['media_files']:
            media_url = media.get('url') if isinstance(media, dict) else None
            if media_url:
                media_urls.add(media_url)
                all_media.append(media)

        legacy_design_image = design.get('design_image')
        if not all_media and legacy_design_image:
            all_media.append({
                'type': 'image',
                'url': legacy_design_image,
                'is_main': True
            })
        elif legacy_design_image and legacy_design_image not in media_urls:
            legacy_path = os.path.join('static', legacy_design_image)
            if os.path.exists(legacy_path):
                all_media.insert(0, {
                    'type': 'image',
                    'url': legacy_design_image,
                    'is_main': True
                })

        design['all_media'] = all_media
        
        # Fallback: if no media_files but has design_image, create media_files array
        if not design['media_files'] and design.get('design_image'):
            design['media_files'] = [{
                'type': 'image',
                'url': design['design_image'],
                'order': 0
            }]
    
    # Calculate total
    total = sum(d['price'] or 0 for d in designs)
    
    # Fetch default items with icons for dynamic display
    cur.execute("""
        SELECT id, item_name, item_slug, icon_emoji, icon_image, default_price, description,
               has_length, has_breadth, has_height, display_order, is_active
        FROM default_items
        WHERE is_active = TRUE
        ORDER BY display_order, item_name
    """)
    default_items_list = cur.fetchall()
    default_items = [dict(row) for row in default_items_list]
    
    cur.close()
    conn.close()
    
    return render_template('quotation_view_simple.html',
                         lead=lead, designs=designs, total=total, default_items=default_items,
                         current_user=current_user)

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
               default_price, description, has_length, has_breadth, has_height,
               display_order, is_active
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
        has_length = 'has_length' in request.form
        has_breadth = 'has_breadth' in request.form
        has_height = 'has_height' in request.form
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
                
                # Resize image to icon size (64x64) to reduce file size
                try:
                    from PIL import Image
                    img = Image.open(file.stream)
                    
                    # Convert RGBA to RGB if needed
                    if img.mode == 'RGBA':
                        background = Image.new('RGB', img.size, (255, 255, 255))
                        background.paste(img, mask=img.split()[3])
                        img = background
                    
                    # Resize to 64x64 maintaining aspect ratio
                    img.thumbnail((64, 64), Image.Resampling.LANCZOS)
                    
                    # Save with optimization
                    img.save(filepath, optimize=True, quality=85)
                except ImportError:
                    # Fallback if PIL not available
                    file.seek(0)
                    file.save(filepath)
                
                icon_image = f"img/icons/{filename}"
        
        # Insert new item
        cur.execute("""
            INSERT INTO default_items
            (item_name, item_slug, icon_emoji, icon_image, default_price,
             description, has_length, has_breadth, has_height, display_order, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (item_name, item_slug, icon_emoji, icon_image, default_price,
              description, has_length, has_breadth, has_height, display_order, is_active))
        
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
        has_length = 'has_length' in request.form
        has_breadth = 'has_breadth' in request.form
        has_height = 'has_height' in request.form
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
                
                # Resize image to icon size (64x64) to reduce file size
                try:
                    from PIL import Image
                    img = Image.open(file.stream)
                    
                    # Convert RGBA to RGB if needed
                    if img.mode == 'RGBA':
                        background = Image.new('RGB', img.size, (255, 255, 255))
                        background.paste(img, mask=img.split()[3])
                        img = background
                    
                    # Resize to 64x64 maintaining aspect ratio
                    img.thumbnail((64, 64), Image.Resampling.LANCZOS)
                    
                    # Save with optimization
                    img.save(filepath, optimize=True, quality=85)
                except ImportError:
                    # Fallback if PIL not available
                    file.stream.seek(0)
                    file.save(filepath)
                
                icon_image_update = f", icon_image = 'img/icons/{filename}'"
        
        # Update item
        cur.execute(f"""
            UPDATE default_items
            SET item_name = %s, item_slug = %s, icon_emoji = %s,
                default_price = %s, description = %s,
                has_length = %s, has_breadth = %s, has_height = %s,
                display_order = %s, is_active = %s, updated_at = CURRENT_TIMESTAMP
                {icon_image_update}
            WHERE id = %s
        """, (item_name, item_slug, icon_emoji, default_price, description,
              has_length, has_breadth, has_height, display_order, is_active, item_id))
        
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

@leads_bp.route('/admin/leads/design/<int:design_id>/upload_media', methods=['POST'])
@admin_required
def upload_design_media(design_id):
    """Upload media files to design gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        lead_id = request.args.get('lead_id')
        
        # Get current media files
        cur.execute("SELECT media_files FROM lead_designs WHERE id = %s", (design_id,))
        result = cur.fetchone()
        media_files = result['media_files'] if result and result['media_files'] else []
        
        # Count current files
        image_count = sum(1 for m in media_files if m.get('type') == 'image')
        video_count = sum(1 for m in media_files if m.get('type') == 'video')
        
        # Process uploaded files
        files = request.files.getlist('media_files')
        
        for file in files:
            if not file or not file.filename:
                continue
                
            # Validate file type
            ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
            is_image = ext in ['png', 'jpg', 'jpeg', 'gif', 'webp']
            is_video = ext in ['mp4', 'webm', 'mov']
            
            if not (is_image or is_video):
                flash(f'Invalid file type: {file.filename}', 'danger')
                continue
            
            # Check limits
            if is_image and image_count >= 3:
                flash('Maximum 3 images allowed', 'warning')
                continue
            if is_video and video_count >= 2:
                flash('Maximum 2 videos allowed', 'warning')
                continue
            if len(media_files) >= 5:
                flash('Maximum 5 files allowed', 'warning')
                break
            
            # Check file size
            file.seek(0, 2)  # Seek to end
            file_size = file.tell()
            file.seek(0)  # Reset
            
            max_size = 5 * 1024 * 1024 if is_image else 50 * 1024 * 1024
            if file_size > max_size:
                size_mb = max_size / (1024 * 1024)
                flash(f'{file.filename} exceeds {size_mb}MB limit', 'danger')
                continue
            
            # Save file
            filename = secure_filename(file.filename)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            order = len(media_files) + 1
            filename = f"design_{design_id}_{order}_{timestamp}_{filename}"
            
            media_folder = os.path.join('static', 'img', 'leads', 'media')
            os.makedirs(media_folder, exist_ok=True)
            filepath = os.path.join(media_folder, filename)
            file.save(filepath)
            
            # Add to media_files
            media_files.append({
                'type': 'image' if is_image else 'video',
                'url': f"img/leads/media/{filename}",
                'order': order,
                'size': file_size,
                'filename': file.filename
            })
            
            if is_image:
                image_count += 1
            else:
                video_count += 1
        
        # Update database
        cur.execute("""
            UPDATE lead_designs
            SET media_files = %s
            WHERE id = %s
        """, (json.dumps(media_files), design_id))
        
        conn.commit()
        flash('Media files uploaded successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error uploading media: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/admin/leads/design/<int:design_id>/delete_media/<int:media_index>', methods=['POST'])
@admin_required
def delete_design_media(design_id, media_index):
    """Delete a media file from design gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        lead_id = request.args.get('lead_id')
        
        # Get current media files
        cur.execute("SELECT media_files FROM lead_designs WHERE id = %s", (design_id,))
        result = cur.fetchone()
        media_files = result['media_files'] if result and result['media_files'] else []
        
        if 0 <= media_index < len(media_files):
            # Delete file from filesystem
            file_path = os.path.join('static', media_files[media_index]['url'])
            if os.path.exists(file_path):
                os.remove(file_path)
            
            # Remove from array
            media_files.pop(media_index)
            
            # Reorder remaining files
            for i, media in enumerate(media_files):
                media['order'] = i + 1
            
            # Update database
            cur.execute("""
                UPDATE lead_designs
                SET media_files = %s
                WHERE id = %s
            """, (json.dumps(media_files), design_id))
            
            conn.commit()
            flash('Media file deleted successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error deleting media: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=lead_id))

@leads_bp.route('/api/submit-quotation-feedback', methods=['POST'])
def submit_quotation_feedback():
    """Handle customer feedback submission for quotations"""
    try:
        lead_id = request.form.get('lead_id')
        rating = request.form.get('rating', '0')
        message = request.form.get('message', '').strip()
        
        # Validate input
        if not lead_id:
            return jsonify({'success': False, 'message': 'Lead ID is required'}), 400
        
        # Convert rating to integer
        try:
            rating = int(rating)
            if rating < 0 or rating > 5:
                rating = 0
        except (ValueError, TypeError):
            rating = 0
        
        # At least one field should be provided
        if not message:
            return jsonify({'success': False, 'message': 'Please provide your feedback'}), 400
        
        # Update database
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if lead exists and get share token
        cur.execute("SELECT share_token FROM leads WHERE id = %s", (lead_id,))
        result = cur.fetchone()
        if not result:
            cur.close()
            conn.close()
            return jsonify({'success': False, 'message': 'Quotation not found'}), 404
        
        share_token = result[0]
        
        # Update feedback
        cur.execute("""
            UPDATE leads
            SET customer_rating = %s,
                customer_feedback = %s,
                feedback_submitted_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (rating if rating > 0 else None, message if message else None, lead_id))
        
        conn.commit()
        cur.close()
        conn.close()
        
        # Return JSON success response
        return jsonify({
            'success': True,
            'message': 'Thank you for your feedback!',
            'share_token': share_token
        })
        
    except Exception as e:
        print(f"Error submitting feedback: {str(e)}")
        return jsonify({'success': False, 'message': 'An error occurred while submitting your feedback. Please try again.'}), 500

# Keep the old HTML response version for backwards compatibility (if needed)
@leads_bp.route('/submit-quotation-feedback-html', methods=['POST'])
def submit_quotation_feedback_html():
    """Handle customer feedback submission for quotations - HTML response version"""
    try:
        lead_id = request.form.get('lead_id')
        rating = request.form.get('rating', '0')
        message = request.form.get('message', '').strip()
        
        # Validate input
        if not lead_id:
            return render_template_string('''
                <div style="max-width: 600px; margin: 50px auto; padding: 40px; text-align: center; font-family: Arial, sans-serif;">
                    <div style="color: #dc2626; font-size: 48px; margin-bottom: 20px;">❌</div>
                    <h2 style="color: #dc2626; margin-bottom: 20px;">Error</h2>
                    <p style="color: #64748b; font-size: 18px;">Lead ID is required</p>
                </div>
            '''), 400
        
        # Convert rating to integer
        try:
            rating = int(rating)
            if rating < 0 or rating > 5:
                rating = 0
        except (ValueError, TypeError):
            rating = 0
        
        # At least one field should be provided
        if not message:
            return render_template_string('''
                <div style="max-width: 600px; margin: 50px auto; padding: 40px; text-align: center; font-family: Arial, sans-serif;">
                    <div style="color: #dc2626; font-size: 48px; margin-bottom: 20px;">❌</div>
                    <h2 style="color: #dc2626; margin-bottom: 20px;">Error</h2>
                    <p style="color: #64748b; font-size: 18px;">Please provide your feedback</p>
                </div>
            '''), 400
        
        # Update database
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if lead exists and get share token
        cur.execute("SELECT share_token FROM leads WHERE id = %s", (lead_id,))
        result = cur.fetchone()
        if not result:
            cur.close()
            conn.close()
            return render_template_string('''
                <div style="max-width: 600px; margin: 50px auto; padding: 40px; text-align: center; font-family: Arial, sans-serif;">
                    <div style="color: #dc2626; font-size: 48px; margin-bottom: 20px;">❌</div>
                    <h2 style="color: #dc2626; margin-bottom: 20px;">Error</h2>
                    <p style="color: #64748b; font-size: 18px;">Quotation not found</p>
                </div>
            '''), 404
        
        share_token = result[0]
        
        # Update feedback
        cur.execute("""
            UPDATE leads
            SET customer_rating = %s,
                customer_feedback = %s,
                feedback_submitted_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (rating if rating > 0 else None, message if message else None, lead_id))
        
        conn.commit()
        cur.close()
        conn.close()
        
        # Return beautiful thank you page
        return render_template_string('''
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Thank You - GSpaces</title>
                <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
            </head>
            <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center;">
                <div style="max-width: 600px; margin: 20px; padding: 60px 40px; background: white; border-radius: 24px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); text-align: center;">
                    <div style="width: 100px; height: 100px; margin: 0 auto 30px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); border-radius: 50%; display: flex; align-items: center; justify-content: center; animation: scaleIn 0.5s ease-out;">
                        <i class="bi bi-check-lg" style="font-size: 60px; color: white;"></i>
                    </div>
                    
                    <h1 style="color: #1e293b; font-size: 36px; font-weight: 700; margin-bottom: 20px; line-height: 1.2;">
                        Thank You for Your Feedback!
                    </h1>
                    
                    <p style="color: #64748b; font-size: 20px; line-height: 1.6; margin-bottom: 30px;">
                        We appreciate you taking the time to share your thoughts with us.
                    </p>
                    
                    <div style="background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%); padding: 30px; border-radius: 16px; margin-bottom: 40px; border-left: 4px solid #0ea5e9;">
                        <p style="color: #0c4a6e; font-size: 18px; line-height: 1.8; margin: 0; font-weight: 500;">
                            <i class="bi bi-heart-fill" style="color: #ef4444; margin-right: 8px;"></i>
                            We always strive to provide the <strong>best prices</strong> and <strong>exceptional service</strong> to our valued customers.
                        </p>
                    </div>
                    
                    <a href="/quotation/{{ share_token }}" style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 48px; border-radius: 12px; text-decoration: none; font-weight: 600; font-size: 18px; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3); transition: all 0.3s;">
                        <i class="bi bi-arrow-left-circle" style="margin-right: 8px;"></i>
                        Back to Quotation
                    </a>
                    
                    <p style="color: #94a3b8; font-size: 14px; margin-top: 40px; margin-bottom: 0;">
                        <i class="bi bi-envelope" style="margin-right: 6px;"></i>
                        Need help? Contact us anytime
                    </p>
                </div>
                
                <style>
                    @keyframes scaleIn {
                        from {
                            transform: scale(0);
                            opacity: 0;
                        }
                        to {
                            transform: scale(1);
                            opacity: 1;
                        }
                    }
                    
                    a:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 6px 20px rgba(79, 70, 229, 0.4) !important;
                    }
                </style>
            </body>
            </html>
        ''', share_token=share_token)
        
    except Exception as e:
        print(f"Error submitting feedback: {str(e)}")
        return render_template_string('''
            <div style="max-width: 600px; margin: 50px auto; padding: 40px; text-align: center; font-family: Arial, sans-serif;">
                <div style="color: #dc2626; font-size: 48px; margin-bottom: 20px;">❌</div>
                <h2 style="color: #dc2626; margin-bottom: 20px;">Error</h2>
                <p style="color: #64748b; font-size: 18px;">An error occurred while submitting your feedback. Please try again.</p>
            </div>
        '''), 500

@leads_bp.route('/api/delete-quotation-feedback', methods=['POST'])
def delete_quotation_feedback():
    """Handle customer feedback deletion - Admin only"""
    try:
        lead_id = request.form.get('lead_id')
        
        if not lead_id:
            return jsonify({'success': False, 'message': 'Lead ID is required'}), 400
        
        # Update database
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Clear feedback
        cur.execute("""
            UPDATE leads
            SET customer_rating = NULL,
                customer_feedback = NULL,
                feedback_submitted_at = NULL
            WHERE id = %s
        """, (lead_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Feedback deleted successfully'})
        
    except Exception as e:
        print(f"Error deleting feedback: {str(e)}")
        return jsonify({'success': False, 'message': 'An error occurred while deleting feedback'}), 500

@leads_bp.route('/api/delete-quotation-feedback-old', methods=['POST'])
def delete_quotation_feedback_old():
    """Handle customer feedback deletion - Admin only - OLD VERSION"""
    try:
        lead_id = request.form.get('lead_id')
        
        if not lead_id:
            flash('Lead ID is required', 'danger')
            return redirect(request.referrer or '/')
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get share token for redirect
        cur.execute("SELECT share_token FROM leads WHERE id = %s", (lead_id,))
        result = cur.fetchone()
        if not result:
            cur.close()
            conn.close()
            flash('Quotation not found', 'danger')
            return redirect(request.referrer or '/')
        
        share_token = result[0]
        
        # Delete feedback
        cur.execute("""
            UPDATE leads
            SET customer_rating = NULL,
                customer_feedback = NULL,
                feedback_submitted_at = NULL
            WHERE id = %s
        """, (lead_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        flash('Feedback deleted successfully', 'success')
        return redirect(f'/quotation/{share_token}')
        
    except Exception as e:
        print(f"Error deleting feedback: {str(e)}")
        flash('An error occurred while deleting feedback', 'danger')
        return redirect(request.referrer or '/')
@leads_bp.route('/api/update-quotation-expiry', methods=['POST'])
@admin_required
def update_quotation_expiry():
    """Update quotation expiry date - Admin only"""
    try:
        lead_id = request.form.get('lead_id')
        action = request.form.get('action')  # 'extend' or 'expire' or 'set_date'
        custom_date = request.form.get('custom_date')  # Optional custom date
        
        if not lead_id:
            flash('Lead ID is required', 'danger')
            return redirect(request.referrer or '/')
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Get share token for redirect
        cur.execute("SELECT share_token FROM leads WHERE id = %s", (lead_id,))
        result = cur.fetchone()
        if not result:
            cur.close()
            conn.close()
            flash('Quotation not found', 'danger')
            return redirect(request.referrer or '/')
        
        share_token = result[0]
        
        # Update expiry based on action
        if action == 'extend':
            # Extend by 7 days from now
            cur.execute("""
                UPDATE leads
                SET valid_until = CURRENT_TIMESTAMP + INTERVAL '7 days',
                    is_expired = FALSE
                WHERE id = %s
            """, (lead_id,))
            flash('Quotation validity extended by 7 days', 'success')
            
        elif action == 'expire':
            # Mark as expired immediately
            cur.execute("""
                UPDATE leads
                SET is_expired = TRUE
                WHERE id = %s
            """, (lead_id,))
            flash('Quotation marked as expired', 'success')
            
        elif action == 'set_date' and custom_date:
            # Set custom expiry date
            cur.execute("""
                UPDATE leads
                SET valid_until = %s,
                    is_expired = FALSE
                WHERE id = %s
            """, (custom_date, lead_id))
            flash(f'Quotation expiry set to {custom_date}', 'success')
        else:
            flash('Invalid action', 'danger')
            cur.close()
            conn.close()
            return redirect(request.referrer or '/')
        
        conn.commit()
        cur.close()
        conn.close()
        
        return redirect(f'/quotation/{share_token}')
        
    except Exception as e:
        print(f"Error updating expiry: {str(e)}")
        flash('An error occurred while updating expiry', 'danger')
        return redirect(request.referrer or '/')



def register_leads_routes(app, db_connection_func):
    """Register blueprint with app"""
    global get_db_connection
    get_db_connection = db_connection_func
    app.register_blueprint(leads_bp)

# Made with Bob
