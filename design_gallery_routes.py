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
        cur.execute("""
            SELECT 
                id,
                title,
                description,
                image_url,
                category
            FROM design_gallery
            WHERE is_active = TRUE
            ORDER BY display_order, created_at DESC
        """)
        designs = cur.fetchall()
        
        return render_template('design_gallery_public.html', designs=designs)
    finally:
        cur.close()
        conn.close()

# Made with Bob
