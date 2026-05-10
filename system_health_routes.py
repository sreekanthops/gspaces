from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from functools import wraps
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime, timedelta
import psutil
import platform

system_health_bp = Blueprint('system_health', __name__)

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

@system_health_bp.route('/admin/system-health')
@login_required
@admin_required
def system_health():
    """Main system health dashboard"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get log statistics
        cur.execute("""
            SELECT 
                log_level,
                COUNT(*) as count
            FROM system_logs
            WHERE created_at > NOW() - INTERVAL '24 hours'
            GROUP BY log_level
        """)
        log_stats = cur.fetchall()
        
        # Get error count
        cur.execute("""
            SELECT COUNT(*) as count
            FROM error_logs
            WHERE resolved = FALSE
        """)
        unresolved_errors = cur.fetchone()['count']
        
        # Get recent errors
        cur.execute("""
            SELECT 
                id,
                error_type,
                error_message,
                route,
                method,
                created_at,
                resolved
            FROM error_logs
            ORDER BY created_at DESC
            LIMIT 10
        """)
        recent_errors = cur.fetchall()
        
        # Get system metrics
        system_info = {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'platform': platform.system(),
            'python_version': platform.python_version(),
        }
        
        # Get database size
        cur.execute("""
            SELECT pg_size_pretty(pg_database_size(current_database())) as db_size
        """)
        db_info = cur.fetchone()
        system_info['database_size'] = db_info['db_size']
        
        # Get table counts
        cur.execute("""
            SELECT 
                (SELECT COUNT(*) FROM system_logs) as system_logs,
                (SELECT COUNT(*) FROM error_logs) as error_logs,
                (SELECT COUNT(*) FROM api_request_logs) as api_logs,
                (SELECT COUNT(*) FROM system_metrics) as metrics
        """)
        table_counts = cur.fetchone()
        
        return render_template('admin_system_health.html',
                             log_stats=log_stats,
                             unresolved_errors=unresolved_errors,
                             recent_errors=recent_errors,
                             system_info=system_info,
                             table_counts=table_counts)
    finally:
        cur.close()
        conn.close()

@system_health_bp.route('/admin/system-health/logs')
@login_required
@admin_required
def view_logs():
    """View system logs with filtering"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Get filter parameters
    log_level = request.args.get('level', '')
    log_type = request.args.get('type', '')
    hours = request.args.get('hours', '24')
    page = int(request.args.get('page', 1))
    per_page = 50
    
    try:
        # Build query with filters
        query = """
            SELECT 
                id,
                log_level,
                log_type,
                message,
                route,
                method,
                status_code,
                response_time,
                ip_address,
                created_at
            FROM system_logs
            WHERE created_at > NOW() - INTERVAL '%s hours'
        """ % hours
        
        if log_level:
            query += f" AND log_level = '{log_level}'"
        if log_type:
            query += f" AND log_type = '{log_type}'"
        
        query += " ORDER BY created_at DESC"
        query += f" LIMIT {per_page} OFFSET {(page - 1) * per_page}"
        
        cur.execute(query)
        logs = cur.fetchall()
        
        # Get total count for pagination
        count_query = f"""
            SELECT COUNT(*) as total
            FROM system_logs
            WHERE created_at > NOW() - INTERVAL '{hours} hours'
        """
        if log_level:
            count_query += f" AND log_level = '{log_level}'"
        if log_type:
            count_query += f" AND log_type = '{log_type}'"
        
        cur.execute(count_query)
        total = cur.fetchone()['total']
        total_pages = (total + per_page - 1) // per_page
        
        return render_template('admin_system_logs.html',
                             logs=logs,
                             page=page,
                             total_pages=total_pages,
                             log_level=log_level,
                             log_type=log_type,
                             hours=hours)
    finally:
        cur.close()
        conn.close()

@system_health_bp.route('/admin/system-health/errors')
@login_required
@admin_required
def view_errors():
    """View error logs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    show_resolved = request.args.get('resolved', 'false') == 'true'
    page = int(request.args.get('page', 1))
    per_page = 20
    
    try:
        query = """
            SELECT 
                id,
                error_type,
                error_message,
                route,
                method,
                ip_address,
                created_at,
                resolved,
                resolved_at
            FROM error_logs
        """
        
        if not show_resolved:
            query += " WHERE resolved = FALSE"
        
        query += " ORDER BY created_at DESC"
        query += f" LIMIT {per_page} OFFSET {(page - 1) * per_page}"
        
        cur.execute(query)
        errors = cur.fetchall()
        
        # Get total count
        count_query = "SELECT COUNT(*) as total FROM error_logs"
        if not show_resolved:
            count_query += " WHERE resolved = FALSE"
        
        cur.execute(count_query)
        total = cur.fetchone()['total']
        total_pages = (total + per_page - 1) // per_page
        
        return render_template('admin_error_logs.html',
                             errors=errors,
                             page=page,
                             total_pages=total_pages,
                             show_resolved=show_resolved)
    finally:
        cur.close()
        conn.close()

@system_health_bp.route('/admin/system-health/error/<int:error_id>')
@login_required
@admin_required
def error_detail(error_id):
    """View detailed error information"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute("""
            SELECT *
            FROM error_logs
            WHERE id = %s
        """, (error_id,))
        error = cur.fetchone()
        
        if not error:
            flash("Error not found", "danger")
            return redirect(url_for('system_health.view_errors'))
        
        return render_template('admin_error_detail.html', error=error)
    finally:
        cur.close()
        conn.close()

@system_health_bp.route('/admin/system-health/error/<int:error_id>/resolve', methods=['POST'])
@login_required
@admin_required
def resolve_error(error_id):
    """Mark an error as resolved"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("""
            UPDATE error_logs
            SET resolved = TRUE,
                resolved_at = NOW(),
                resolved_by = %s
            WHERE id = %s
        """, (current_user.id, error_id))
        conn.commit()
        
        flash("Error marked as resolved", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error resolving: {str(e)}", "danger")
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('system_health.view_errors'))

@system_health_bp.route('/admin/system-health/clean-logs', methods=['POST'])
@login_required
@admin_required
def clean_logs():
    """Clean old logs based on time period"""
    days = request.form.get('days', type=int)
    
    if not days or days < 1:
        flash("Invalid number of days", "danger")
        return redirect(url_for('system_health.system_health'))
    
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Call the clean_old_logs function
        cur.execute("SELECT * FROM clean_old_logs(%s)", (days,))
        result = cur.fetchone()
        conn.commit()
        
        flash(f"Cleaned logs older than {days} days: "
              f"{result['system_logs_deleted']} system logs, "
              f"{result['error_logs_deleted']} error logs, "
              f"{result['api_logs_deleted']} API logs, "
              f"{result['metrics_deleted']} metrics", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error cleaning logs: {str(e)}", "danger")
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('system_health.system_health'))

@system_health_bp.route('/admin/system-health/api-logs')
@login_required
@admin_required
def api_logs():
    """View API request logs"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    route_filter = request.args.get('route', '')
    status_filter = request.args.get('status', '')
    hours = request.args.get('hours', '24')
    page = int(request.args.get('page', 1))
    per_page = 50
    
    try:
        query = """
            SELECT 
                id,
                route,
                method,
                status_code,
                response_time,
                ip_address,
                created_at
            FROM api_request_logs
            WHERE created_at > NOW() - INTERVAL '%s hours'
        """ % hours
        
        if route_filter:
            query += f" AND route LIKE '%{route_filter}%'"
        if status_filter:
            query += f" AND status_code = {status_filter}"
        
        query += " ORDER BY created_at DESC"
        query += f" LIMIT {per_page} OFFSET {(page - 1) * per_page}"
        
        cur.execute(query)
        logs = cur.fetchall()
        
        # Get total count
        count_query = f"""
            SELECT COUNT(*) as total
            FROM api_request_logs
            WHERE created_at > NOW() - INTERVAL '{hours} hours'
        """
        if route_filter:
            count_query += f" AND route LIKE '%{route_filter}%'"
        if status_filter:
            count_query += f" AND status_code = {status_filter}"
        
        cur.execute(count_query)
        total = cur.fetchone()['total']
        total_pages = (total + per_page - 1) // per_page
        
        return render_template('admin_api_logs.html',
                             logs=logs,
                             page=page,
                             total_pages=total_pages,
                             route_filter=route_filter,
                             status_filter=status_filter,
                             hours=hours)
    finally:
        cur.close()
        conn.close()

@system_health_bp.route('/admin/system-health/metrics')
@login_required
@admin_required
def system_metrics():
    """View system performance metrics"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    metric_type = request.args.get('type', 'CPU')
    hours = request.args.get('hours', '24')
    
    try:
        cur.execute("""
            SELECT 
                metric_name,
                metric_value,
                unit,
                recorded_at
            FROM system_metrics
            WHERE metric_type = %s
            AND recorded_at > NOW() - INTERVAL '%s hours'
            ORDER BY recorded_at DESC
            LIMIT 100
        """ % ('%s', hours), (metric_type,))
        metrics = cur.fetchall()
        
        return render_template('admin_system_metrics.html',
                             metrics=metrics,
                             metric_type=metric_type,
                             hours=hours)
    finally:
        cur.close()
        conn.close()

# Made with Bob
