from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from functools import wraps
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from werkzeug.utils import secure_filename

design_gallery_bp = Blueprint('design_gallery', __name__)

UPLOAD_FOLDER = 'static/img/designs'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def get_db_connection():
    """Create database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'gspaces'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@design_gallery_bp.route('/admin/design-gallery')
@login_required
@admin_required
def admin_design_gallery():
    """Admin page for managing design gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("""
            SELECT 
                id,
                title,
                description,
                image_url,
                display_order,
                is_active,
                category,
                created_at
            FROM design_gallery
            ORDER BY display_order, created_at DESC
        """)
        designs = cur.fetchall()
        
        return render_template('admin_design_gallery.html', designs=designs)
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/add', methods=['POST'])
@login_required
@admin_required
def add_design():
    """Add a new design to gallery"""
    title = request.form.get('title')
    description = request.form.get('description', '')
    category = request.form.get('category', 'office')
    display_order = request.form.get('display_order', 0, type=int)
    
    if not title:
        flash('Title is required', 'danger')
        return redirect(url_for('design_gallery.admin_design_gallery'))
    
    # Handle file upload
    if 'image' not in request.files:
        flash('No image file provided', 'danger')
        return redirect(url_for('design_gallery.admin_design_gallery'))
    
    file = request.files['image']
    if file.filename == '':
        flash('No image selected', 'danger')
        return redirect(url_for('design_gallery.admin_design_gallery'))
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        # Add timestamp to filename to avoid conflicts
        import time
        filename = f"{int(time.time())}_{filename}"
        
        # Create upload directory if it doesn't exist
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        image_url = f'/static/img/designs/{filename}'
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                INSERT INTO design_gallery (title, description, image_url, display_order, category, created_by)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (title, description, image_url, display_order, category, current_user.id))
            conn.commit()
            flash(f'Design "{title}" added successfully', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error adding design: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
    else:
        flash('Invalid file type. Allowed: PNG, JPG, JPEG, GIF, WEBP', 'danger')
    
    return redirect(url_for('design_gallery.admin_design_gallery'))

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/update', methods=['POST'])
@login_required
@admin_required
def update_design(design_id):
    """Update design title and description"""
    title = request.form.get('title')
    description = request.form.get('description', '')
    category = request.form.get('category', 'office')
    display_order = request.form.get('display_order', 0, type=int)
    
    if not title:
        return jsonify({'error': 'Title is required'}), 400
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("""
            UPDATE design_gallery
            SET title = %s,
                description = %s,
                category = %s,
                display_order = %s,
                updated_at = NOW()
            WHERE id = %s
        """, (title, description, category, display_order, design_id))
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Design updated successfully'})
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_design(design_id):
    """Delete a design from gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get image URL before deleting
        cur.execute("SELECT image_url FROM design_gallery WHERE id = %s", (design_id,))
        design = cur.fetchone()
        
        if design:
            # Delete from database
            cur.execute("DELETE FROM design_gallery WHERE id = %s", (design_id,))
            conn.commit()
            
            # Try to delete file from filesystem
            try:
                if design['image_url'].startswith('/static/'):
                    filepath = design['image_url'][1:]  # Remove leading slash
                    if os.path.exists(filepath):
                        os.remove(filepath)
            except Exception as e:
                print(f"Error deleting file: {e}")
            
            flash('Design deleted successfully', 'success')
        else:
            flash('Design not found', 'danger')
    except Exception as e:
        conn.rollback()
        flash(f'Error deleting design: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('design_gallery.admin_design_gallery'))

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/toggle', methods=['POST'])
@login_required
@admin_required
def toggle_design(design_id):
    """Toggle active status of a design"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("""
            UPDATE design_gallery
            SET is_active = NOT is_active,
                updated_at = NOW()
            WHERE id = %s
        """, (design_id,))
        conn.commit()
        flash('Design status updated', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error updating design: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('design_gallery.admin_design_gallery'))

@design_gallery_bp.route('/designs')
def public_gallery():
    """Public gallery page for users"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get all active designs with their media and pricing
        cur.execute("""
            SELECT
                dg.id,
                dg.title,
                dg.description,
                dg.image_url,
                dg.category,
                ld.price as quoted_price,
                ld.type as design_type,
                COUNT(di.id) as image_count
            FROM design_gallery dg
            LEFT JOIN design_images di ON dg.id = di.design_id
            LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id
            WHERE dg.is_active = TRUE
            GROUP BY
                dg.id,
                dg.title,
                dg.description,
                dg.image_url,
                dg.category,
                dg.display_order,
                dg.created_at,
                ld.price,
                ld.type
            ORDER BY dg.display_order, dg.created_at DESC
        """)
        designs = cur.fetchall()
        
        # Get all media for each design for carousel
        for design in designs:
            cur.execute("""
                SELECT image_url, video_url, media_type, display_order
                FROM design_images
                WHERE design_id = %s
                ORDER BY is_primary DESC, display_order, created_at
            """, (design['id'],))
            design['all_media'] = cur.fetchall()
            
            # If no media in design_images, use main image
            if not design['all_media']:
                design['all_media'] = [{
                    'image_url': design['image_url'],
                    'video_url': None,
                    'media_type': 'image',
                    'display_order': 0
                }]
        
        # Get active categories dynamically
        cur.execute("""
            SELECT DISTINCT category, COUNT(*) as count
            FROM design_gallery
            WHERE is_active = TRUE AND category IS NOT NULL
            GROUP BY category
            ORDER BY count DESC
        """)
        categories = cur.fetchall()
        
        return render_template('design_gallery_public.html', designs=designs, categories=categories)
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/designs/<int:design_id>')
def view_design_gallery(design_id):
    """View all images for a specific design"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get design details with linked quotation data when available
        cur.execute("""
            SELECT
                dg.id,
                dg.title,
                dg.description,
                dg.category,
                dg.lead_design_id,
                ld.price AS quoted_price,
                ld.notes,
                ld.custom_items,
                ld.has_table, ld.table_quantity, ld.table_price, ld.table_details, ld.table_length_ft, ld.table_width_ft, ld.table_height_inch,
                ld.has_chair, ld.chair_quantity, ld.chair_price, ld.chair_details, ld.chair_headrest,
                ld.has_lighting, ld.lighting_quantity, ld.lighting_price, ld.lighting_details, ld.lighting_length_ft,
                ld.has_profile_lighting, ld.profile_lighting_quantity, ld.profile_lighting_price, ld.profile_lighting_details, ld.profile_lighting_length_ft,
                ld.has_storage, ld.storage_quantity, ld.storage_price, ld.storage_details, ld.storage_length_ft, ld.storage_width_ft, ld.storage_height_ft,
                ld.has_big_plants, ld.big_plants_quantity, ld.big_plants_price, ld.big_plants_details, ld.big_plants_height_ft,
                ld.has_mini_plants, ld.mini_plants_quantity, ld.mini_plants_price, ld.mini_plants_details, ld.mini_plants_height_ft,
                ld.has_frames, ld.frames_quantity, ld.frames_price, ld.frames_details, ld.frames_size_ft,
                ld.has_wall_racks, ld.wall_racks_quantity, ld.wall_racks_price, ld.wall_racks_details, ld.wall_racks_length_ft,
                ld.has_dustbin, ld.dustbin_quantity, ld.dustbin_price, ld.dustbin_details,
                ld.has_paint, ld.paint_quantity, ld.paint_price, ld.paint_details,
                ld.has_wardrobes, ld.wardrobes_quantity, ld.wardrobes_price, ld.wardrobes_details, ld.wardrobes_length_ft, ld.wardrobes_width_ft, ld.wardrobes_height_ft,
                ld.has_desk_mat, ld.desk_mat_quantity, ld.desk_mat_price, ld.desk_mat_details, ld.desk_mat_length, ld.desk_mat_height,
                ld.has_multi_socket, ld.multi_socket_quantity, ld.multi_socket_price, ld.multi_socket_details,
                ld.has_desk_lamp, ld.desk_lamp_quantity, ld.desk_lamp_price, ld.desk_lamp_details,
                ld.has_pen_holder, ld.pen_holder_quantity, ld.pen_holder_price, ld.pen_holder_details,
                ld.has_laptop_holder, ld.laptop_holder_quantity, ld.laptop_holder_price, ld.laptop_holder_details
            FROM design_gallery dg
            LEFT JOIN lead_designs ld ON dg.lead_design_id = ld.id
            WHERE dg.id = %s AND dg.is_active = TRUE
        """, (design_id,))
        design = cur.fetchone()
        
        if not design:
            flash('Design not found', 'danger')
            return redirect(url_for('design_gallery.public_gallery'))
        
        # Get all images for this design
        cur.execute("""
            SELECT id, image_url, video_url, thumbnail_url, media_type,
                   display_order, is_primary
            FROM design_images
            WHERE design_id = %s
            ORDER BY is_primary DESC, display_order, created_at
        """, (design_id,))
        images = cur.fetchall()

        # If no images in design_images, use the main image_url
        if not images:
            cur.execute("SELECT image_url FROM design_gallery WHERE id = %s", (design_id,))
            main_image = cur.fetchone()
            if main_image and main_image['image_url']:
                images = [{
                    'id': None,  # No ID for fallback image
                    'image_url': main_image['image_url'],
                    'video_url': None,
                    'thumbnail_url': None,
                    'media_type': 'image',
                    'is_primary': True,
                    'display_order': 0
                }]
        
        included_items = []

        def add_item(label, enabled, quantity=None, price=None, details=None, meta=None):
            if enabled:
                included_items.append({
                    'label': label,
                    'quantity': quantity,
                    'price': float(price) if price is not None else None,
                    'details': details,
                    'meta': [value for value in (meta or []) if value]
                })

        if design.get('lead_design_id'):
            add_item(
                'Table',
                design.get('has_table'),
                design.get('table_quantity'),
                design.get('table_price'),
                design.get('table_details'),
                [
                    f"{design.get('table_length_ft')} ft L" if design.get('table_length_ft') else None,
                    f"{design.get('table_width_ft')} ft W" if design.get('table_width_ft') else None,
                    f"{design.get('table_height_inch')} in H" if design.get('table_height_inch') else None
                ]
            )
            add_item('Chair', design.get('has_chair'), design.get('chair_quantity'), design.get('chair_price'), design.get('chair_details'), [design.get('chair_headrest')])
            add_item('Lighting', design.get('has_lighting'), design.get('lighting_quantity'), design.get('lighting_price'), design.get('lighting_details'), [f"{design.get('lighting_length_ft')} ft" if design.get('lighting_length_ft') else None])
            add_item('Profile Lighting', design.get('has_profile_lighting'), design.get('profile_lighting_quantity'), design.get('profile_lighting_price'), design.get('profile_lighting_details'), [f"{design.get('profile_lighting_length_ft')} ft" if design.get('profile_lighting_length_ft') else None])
            add_item(
                'Storage',
                design.get('has_storage'),
                design.get('storage_quantity'),
                design.get('storage_price'),
                design.get('storage_details'),
                [
                    f"{design.get('storage_length_ft')} ft L" if design.get('storage_length_ft') else None,
                    f"{design.get('storage_width_ft')} ft W" if design.get('storage_width_ft') else None,
                    f"{design.get('storage_height_ft')} ft H" if design.get('storage_height_ft') else None
                ]
            )
            add_item('Big Plants', design.get('has_big_plants'), design.get('big_plants_quantity'), design.get('big_plants_price'), design.get('big_plants_details'), [f"{design.get('big_plants_height_ft')} ft height" if design.get('big_plants_height_ft') else None])
            add_item('Mini Plants', design.get('has_mini_plants'), design.get('mini_plants_quantity'), design.get('mini_plants_price'), design.get('mini_plants_details'), [f"{design.get('mini_plants_height_ft')} ft height" if design.get('mini_plants_height_ft') else None])
            add_item('Frames', design.get('has_frames'), design.get('frames_quantity'), design.get('frames_price'), design.get('frames_details'), [design.get('frames_size_ft')])
            add_item('Wall Racks', design.get('has_wall_racks'), design.get('wall_racks_quantity'), design.get('wall_racks_price'), design.get('wall_racks_details'), [f"{design.get('wall_racks_length_ft')} ft" if design.get('wall_racks_length_ft') else None])
            add_item('Dustbin', design.get('has_dustbin'), design.get('dustbin_quantity'), design.get('dustbin_price'), design.get('dustbin_details'))
            add_item('Paint', design.get('has_paint'), design.get('paint_quantity'), design.get('paint_price'), design.get('paint_details'))
            add_item(
                'Wardrobes',
                design.get('has_wardrobes'),
                design.get('wardrobes_quantity'),
                design.get('wardrobes_price'),
                design.get('wardrobes_details'),
                [
                    f"{design.get('wardrobes_length_ft')} ft L" if design.get('wardrobes_length_ft') else None,
                    f"{design.get('wardrobes_width_ft')} ft W" if design.get('wardrobes_width_ft') else None,
                    f"{design.get('wardrobes_height_ft')} ft H" if design.get('wardrobes_height_ft') else None
                ]
            )
            add_item('Desk Mat', design.get('has_desk_mat'), design.get('desk_mat_quantity'), design.get('desk_mat_price'), design.get('desk_mat_details'), [f"{design.get('desk_mat_length')}" if design.get('desk_mat_length') else None, f"{design.get('desk_mat_height')}" if design.get('desk_mat_height') else None])
            add_item('Multi Socket', design.get('has_multi_socket'), design.get('multi_socket_quantity'), design.get('multi_socket_price'), design.get('multi_socket_details'))
            add_item('Desk Lamp', design.get('has_desk_lamp'), design.get('desk_lamp_quantity'), design.get('desk_lamp_price'), design.get('desk_lamp_details'))
            add_item('Pen Holder', design.get('has_pen_holder'), design.get('pen_holder_quantity'), design.get('pen_holder_price'), design.get('pen_holder_details'))
            add_item('Laptop Holder', design.get('has_laptop_holder'), design.get('laptop_holder_quantity'), design.get('laptop_holder_price'), design.get('laptop_holder_details'))

            for custom_item in (design.get('custom_items') or []):
                included_items.append({
                    'label': custom_item.get('name') or 'Custom Item',
                    'quantity': custom_item.get('quantity'),
                    'price': float(custom_item.get('price')) if custom_item.get('price') is not None else None,
                    'details': custom_item.get('details'),
                    'meta': [
                        f"L: {custom_item.get('length')}" if custom_item.get('length') else None,
                        f"B: {custom_item.get('breadth')}" if custom_item.get('breadth') else None,
                        f"H: {custom_item.get('height')}" if custom_item.get('height') else None
                    ]
                })

        return render_template('design_gallery_view.html', design=design, images=images, included_items=included_items)
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/add-image', methods=['POST'])
@login_required
@admin_required
def add_design_image(design_id):
    """Add additional image to a design"""
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No image selected'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        import time
        filename = f"{int(time.time())}_{filename}"
        
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        image_url = f'/static/img/designs/{filename}'
        display_order = request.form.get('display_order', 0, type=int)
        is_primary = request.form.get('is_primary', 'false') == 'true'
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # If setting as primary, unset other primary images
            if is_primary:
                cur.execute("""
                    UPDATE design_images
                    SET is_primary = false
                    WHERE design_id = %s
                """, (design_id,))
            
            cur.execute("""
                INSERT INTO design_images (design_id, image_url, display_order, is_primary)
                VALUES (%s, %s, %s, %s)
            """, (design_id, image_url, display_order, is_primary))
            conn.commit()
            
            return jsonify({'success': True, 'message': 'Image added successfully', 'image_url': image_url})
        except Exception as e:
            conn.rollback()
            return jsonify({'error': str(e)}), 500
        finally:
            cur.close()
            conn.close()
    else:
        return jsonify({'error': 'Invalid file type'}), 400

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/images')
@login_required
@admin_required
def get_design_images(design_id):
    """Get all images for a design (AJAX)"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("""
            SELECT id, image_url, display_order, is_primary
            FROM design_images
            WHERE design_id = %s
            ORDER BY is_primary DESC, display_order, created_at
        """, (design_id,))
        images = cur.fetchall()
        
        return jsonify({'images': images})
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/image/<int:image_id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_design_image(image_id):
    """Delete a design image"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get image info
        cur.execute("SELECT image_url FROM design_images WHERE id = %s", (image_id,))
        image = cur.fetchone()
        
        if image:
            # Delete from database
            cur.execute("DELETE FROM design_images WHERE id = %s", (image_id,))
            conn.commit()
            
            # Try to delete file
            try:
                if image['image_url'].startswith('/static/'):
                    filepath = image['image_url'][1:]
                    if os.path.exists(filepath):
                        os.remove(filepath)
            except Exception as e:
                print(f"Error deleting file: {e}")
            
            return jsonify({'success': True, 'message': 'Image deleted successfully'})
        else:
            return jsonify({'error': 'Image not found'}), 404
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/manage-media')
@login_required
@admin_required
def manage_design_media(design_id):
    """Page to manage media for a specific design"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get design details
        cur.execute("SELECT * FROM design_gallery WHERE id = %s", (design_id,))
        design = cur.fetchone()
        
        if not design:
            flash('Design not found', 'danger')
            return redirect(url_for('design_gallery.admin_design_gallery'))
        
        # Get all media for this design
        cur.execute("""
            SELECT id, image_url, video_url, media_type, display_order, is_primary
            FROM design_images
            WHERE design_id = %s
            ORDER BY is_primary DESC, display_order, created_at
        """, (design_id,))
        media_files = cur.fetchall()
        
        return render_template('admin_design_media.html', design=design, media_files=media_files)
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/admin/design-gallery/<int:design_id>/set-primary/<int:image_id>', methods=['POST'])
@login_required
@admin_required
def set_primary_image(design_id, image_id):
    """Set an image as primary for a design"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Unset all primary images for this design
        cur.execute("""
            UPDATE design_images
            SET is_primary = FALSE
            WHERE design_id = %s
        """, (design_id,))
        
        # Set the selected image as primary
        cur.execute("""
            UPDATE design_images
            SET is_primary = TRUE
            WHERE id = %s AND design_id = %s
        """, (image_id, design_id))
        
        # Get the new primary image URL
        cur.execute("SELECT image_url FROM design_images WHERE id = %s", (image_id,))
        result = cur.fetchone()
        
        if result:
            # Update design_gallery main image
            cur.execute("""
                UPDATE design_gallery
                SET image_url = %s, updated_at = NOW()
                WHERE id = %s
            """, (result[0], design_id))
        
        conn.commit()
        return jsonify({'success': True, 'message': 'Primary image updated successfully'})
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

# Made with Bob
