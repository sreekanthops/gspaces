"""
Admin User Management Routes
Allows super admins to manage user admin privileges
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
from functools import wraps
import psycopg2
from psycopg2.extras import RealDictCursor

admin_users_bp = Blueprint('admin_users', __name__)

# Import database connection from main app
# This will be set when registering the blueprint
get_db_connection = None

def set_db_connection_func(func):
    """Set the database connection function from main app"""
    global get_db_connection
    get_db_connection = func

def _get_connection():
    """Helper to get database connection with error handling"""
    if get_db_connection is None:
        raise RuntimeError("Database connection function not set. Call set_db_connection_func() first.")
    return get_db_connection()

def admin_required(f):
    """Decorator to require admin access"""
    @login_required
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            flash('Please log in to access this page', 'danger')
            return redirect(url_for('login'))
        
        # Check if user has is_admin attribute and it's True
        if not hasattr(current_user, 'is_admin') or not current_user.is_admin:
            flash('Admin access required', 'danger')
            return redirect(url_for('index'))
        
        return f(*args, **kwargs)
    return decorated_function


def delete_permission_required(f):
    """Decorator to require delete permissions (Full Admin)"""
    @login_required
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            flash('Please log in to access this page', 'danger')
            return redirect(url_for('login'))
        
        # Check if user is admin
        if not hasattr(current_user, 'is_admin') or not current_user.is_admin:
            flash('Admin access required', 'danger')
            return redirect(url_for('index'))
        
        # Check delete permissions
        conn = _get_connection()
        if conn:
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute("SELECT can_delete FROM users WHERE id = %s", (current_user.id,))
                user = cur.fetchone()
                cur.close()
                conn.close()
                
                if not user or not user.get('can_delete', False):
                    flash('Delete permission required. Only Full Admins can perform this action.', 'danger')
                    return redirect(url_for('admin_orders'))
            except:
                if conn:
                    conn.close()
                flash('Permission check failed', 'danger')
                return redirect(url_for('admin_orders'))
        
        return f(*args, **kwargs)
    return decorated_function

def write_permission_required(f):
    """Decorator to require write permissions (Write or Full Admin)"""
    @login_required
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            flash('Please log in to access this page', 'danger')
            return redirect(url_for('login'))
        
        # Check if user is admin
        if not hasattr(current_user, 'is_admin') or not current_user.is_admin:
            flash('Admin access required', 'danger')
            return redirect(url_for('index'))
        
        # Check write permissions
        conn = _get_connection()
        if conn:
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute("SELECT can_write, can_delete FROM users WHERE id = %s", (current_user.id,))
                user = cur.fetchone()
                cur.close()
                conn.close()
                
                if not user or not (user.get('can_write', False) or user.get('can_delete', False)):
                    flash('Write permission required. You only have Read access.', 'warning')
                    return redirect(url_for('admin_orders'))
            except:
                if conn:
                    conn.close()
                flash('Permission check failed', 'danger')
                return redirect(url_for('admin_orders'))
        
        return f(*args, **kwargs)
    return decorated_function


@admin_users_bp.route('/admin/users')
@admin_required
def manage_users():
    """Admin page to manage user privileges"""
    conn = _get_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('admin_orders'))
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get all users with their admin status and permissions
        cur.execute("""
            SELECT id, name, email, phone, is_admin,
                   COALESCE(can_read, FALSE) as can_read,
                   COALESCE(can_write, FALSE) as can_write,
                   COALESCE(can_delete, FALSE) as can_delete,
                   wallet_balance, referral_code,
                   (SELECT COUNT(*) FROM orders WHERE user_id = users.id) as order_count
            FROM users
            ORDER BY is_admin DESC, can_delete DESC, can_write DESC, can_read DESC, id ASC
        """)
        users = cur.fetchall()
        
        # Get stats
        cur.execute("SELECT COUNT(*) as total FROM users")
        total_users = cur.fetchone()['total']
        
        cur.execute("SELECT COUNT(*) as total FROM users WHERE is_admin = true")
        total_admins = cur.fetchone()['total']
        
        cur.close()
        conn.close()
        
        return render_template('admin_users.html',
                             users=users,
                             total_users=total_users,
                             total_admins=total_admins)
    
    except Exception as e:
        print(f"Error fetching users: {e}")
        flash(f'Error loading users: {str(e)}', 'danger')
        if conn:
            conn.close()
        return redirect(url_for('admin_orders'))


@admin_users_bp.route('/admin/users/promote', methods=['POST'])
@admin_required
def promote_user():
    """Promote a user to admin by email with specific permissions"""
    email = request.form.get('email', '').strip()
    permission_level = request.form.get('permission_level', 'read')
    
    if not email:
        flash('Email is required', 'danger')
        return redirect(url_for('admin_users.manage_users'))
    
    # Set permissions based on level
    can_read = True  # All admins can read
    can_write = permission_level in ['write', 'full']
    can_delete = permission_level == 'full'
    
    conn = _get_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('admin_users.manage_users'))
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Check if user exists
        cur.execute("SELECT id, name, email, is_admin FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        
        if not user:
            flash(f'No user found with email: {email}', 'danger')
            cur.close()
            conn.close()
            return redirect(url_for('admin_users.manage_users'))
        
        if user['is_admin']:
            flash(f'{user["name"]} is already an admin', 'info')
            cur.close()
            conn.close()
            return redirect(url_for('admin_users.manage_users'))
        
        # Promote to admin with specified permissions
        cur.execute("""
            UPDATE users
            SET is_admin = true,
                can_read = %s,
                can_write = %s,
                can_delete = %s
            WHERE email = %s
        """, (can_read, can_write, can_delete, email))
        conn.commit()
        
        permission_text = {
            'read': 'Read Only (View admin panel)',
            'write': 'Write Access (View + Edit)',
            'full': 'Full Admin (View + Edit + Delete)'
        }.get(permission_level, 'Read Only')
        
        flash(f'✅ Successfully promoted {user["name"]} ({email}) to admin with {permission_text}!', 'success')
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error promoting user: {e}")
        flash(f'Error promoting user: {str(e)}', 'danger')
        if conn:
            conn.rollback()
            conn.close()
    
    return redirect(url_for('admin_users.manage_users'))


@admin_users_bp.route('/admin/users/<int:user_id>/revoke', methods=['POST'])
@delete_permission_required
def revoke_admin(user_id):
    """Revoke admin access from a user (Full Admin only)"""
    
    # Prevent removing own admin access
    if current_user.id == user_id:
        flash('You cannot remove your own admin access', 'danger')
        return redirect(url_for('admin_users.manage_users'))
    
    conn = _get_connection()
    if not conn:
        flash('Database connection error', 'danger')
        return redirect(url_for('admin_users.manage_users'))
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get current status
        cur.execute("SELECT id, name, email, is_admin FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()
        
        if not user:
            flash('User not found', 'danger')
            cur.close()
            conn.close()
            return redirect(url_for('admin_users.manage_users'))
        
        if not user['is_admin']:
            flash(f'{user["name"]} is not an admin', 'info')
            cur.close()
            conn.close()
            return redirect(url_for('admin_users.manage_users'))
        
        # Revoke admin status and all permissions
        cur.execute("""
            UPDATE users
            SET is_admin = false,
                can_read = false,
                can_write = false,
                can_delete = false
            WHERE id = %s
        """, (user_id,))
        conn.commit()
        
        flash(f'✅ Admin access revoked from {user["name"]}', 'success')
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error toggling admin: {e}")
        flash(f'Error updating user: {str(e)}', 'danger')
        if conn:
            conn.rollback()
            conn.close()
    
    return redirect(url_for('admin_users.manage_users'))


@admin_users_bp.route('/admin/users/search')
@admin_required
def search_users():
    """Search users by email (AJAX endpoint)"""
    query = request.args.get('q', '').strip()
    
    if len(query) < 3:
        return jsonify({'users': []})
    
    conn = _get_connection()
    if not conn:
        return jsonify({'error': 'Database connection error'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT id, name, email, is_admin 
            FROM users 
            WHERE email ILIKE %s OR name ILIKE %s
            LIMIT 10
        """, (f'%{query}%', f'%{query}%'))
        
        users = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return jsonify({'users': [dict(u) for u in users]})
    
    except Exception as e:
        print(f"Error searching users: {e}")
        if conn:
            conn.close()
        return jsonify({'error': str(e)}), 500
