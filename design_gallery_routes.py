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
        # Get all active designs with their image count and quoted price from synced lead designs
        cur.execute("""
            SELECT
                dg.id,
                dg.title,
                dg.description,
                dg.image_url,
                dg.category,
                COALESCE(ld.final_price, ld.price) as quoted_price,
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
                ld.final_price,
                ld.price
            ORDER BY dg.display_order, dg.created_at DESC
        """)
        designs = cur.fetchall()
        
        return render_template('design_gallery_public.html', designs=designs)
    finally:
        cur.close()
        conn.close()

@design_gallery_bp.route('/designs/<int:design_id>')
def view_design_gallery(design_id):
    """View all images for a specific design"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get design details
        cur.execute("""
            SELECT id, title, description, category
            FROM design_gallery
            WHERE id = %s AND is_active = TRUE
        """, (design_id,))
        design = cur.fetchone()
        
        if not design:
            flash('Design not found', 'danger')
            return redirect(url_for('design_gallery.public_gallery'))
        
        # Get all images for this design
        cur.execute("""
            SELECT image_url, video_url, thumbnail_url, media_type,
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
                    'image_url': main_image['image_url'],
                    'video_url': None,
                    'thumbnail_url': None,
                    'media_type': 'image',
                    'is_primary': True,
                    'display_order': 0
                }]
        
        return render_template('design_gallery_view.html', design=design, images=images)
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

# Made with Bob
