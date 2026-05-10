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


def super_admin_required(f):
    """Decorator to require super admin access (admin_level = 1)"""
    @login_required
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            flash('Please log in to access this page', 'danger')
            return redirect(url_for('login'))
        
        # Check if user is super admin (admin_level = 1)
        if not hasattr(current_user, 'is_admin') or not current_user.is_admin:
            flash('Admin access required', 'danger')
            return redirect(url_for('index'))
        
        # Check admin level for delete permissions
        conn = _get_connection()
        if conn:
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute("SELECT admin_level FROM users WHERE id = %s", (current_user.id,))
                user = cur.fetchone()
                cur.close()
                conn.close()
                
                if not user or user.get('admin_level', 2) != 1:
                    flash('Super admin access required for this action', 'danger')
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
        
        # Get all users with their admin status and permission level
        cur.execute("""
            SELECT id, name, email, phone, is_admin,
                   COALESCE(admin_level, 2) as admin_level,
                   wallet_balance, referral_code,
                   (SELECT COUNT(*) FROM orders WHERE user_id = users.id) as order_count
            FROM users
            ORDER BY is_admin DESC, admin_level ASC, id ASC
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
    """Promote a user to admin by email"""
    email = request.form.get('email', '').strip()
    
    if not email:
        flash('Email is required', 'danger')
        return redirect(url_for('admin_users.manage_users'))
    
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
        
        # Promote to admin with regular admin level (2 = no delete permissions)
        cur.execute("""
            UPDATE users
            SET is_admin = true, admin_level = 2
            WHERE email = %s
        """, (email,))
        conn.commit()
        
        flash(f'✅ Successfully promoted {user["name"]} ({email}) to admin! (Limited permissions - no delete access)', 'success')
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error promoting user: {e}")
        flash(f'Error promoting user: {str(e)}', 'danger')
        if conn:
            conn.rollback()
            conn.close()
    
    return redirect(url_for('admin_users.manage_users'))


@admin_users_bp.route('/admin/users/<int:user_id>/toggle-admin', methods=['POST'])
@admin_required
def toggle_admin(user_id):
    """Toggle admin status for a user"""
    
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
        
        # Toggle admin status
        new_status = not user['is_admin']
        cur.execute("UPDATE users SET is_admin = %s WHERE id = %s", (new_status, user_id))
        conn.commit()
        
        action = 'promoted to' if new_status else 'removed from'
        flash(f'✅ {user["name"]} has been {action} admin', 'success')
        
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
