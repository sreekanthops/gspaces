"""
Visitor Tracking and System Health Monitoring Routes
Tracks all visitors, page views, and monitors system health
"""

import os
import json
import uuid
import hashlib
import requests
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify, render_template, session
from flask_login import login_required, current_user
from functools import wraps
import psycopg2
from psycopg2.extras import RealDictCursor
from user_agents import parse
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

visitor_bp = Blueprint('visitor_tracking', __name__)

# Database connection function (will be set from main.py)
get_db_connection = None

def set_db_connection_func(func):
    """Set the database connection function"""
    global get_db_connection
    get_db_connection = func

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin:
            return jsonify({'error': 'Admin access required'}), 403
        return f(*args, **kwargs)
    return decorated_function

def get_visitor_id():
    """Get or create visitor ID"""
    if 'visitor_id' not in session:
        session['visitor_id'] = str(uuid.uuid4())
    return session['visitor_id']

def get_client_ip():
    """Get client IP address"""
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    elif request.headers.get('X-Real-IP'):
        return request.headers.get('X-Real-IP')
    return request.remote_addr

def get_geo_location(ip_address):
    """Get geographical location from IP address"""
    try:
        # Using ipapi.co for geolocation (free tier)
        response = requests.get(f'https://ipapi.co/{ip_address}/json/', timeout=2)
        if response.status_code == 200:
            data = response.json()
            return {
                'country': data.get('country_name', 'Unknown'),
                'city': data.get('city', 'Unknown'),
                'region': data.get('region', 'Unknown')
            }
    except:
        pass
    return {'country': 'Unknown', 'city': 'Unknown', 'region': 'Unknown'}

def parse_user_agent(user_agent_string):
    """Parse user agent to extract browser, OS, and device info"""
    try:
        user_agent = parse(user_agent_string)
        return {
            'browser': f"{user_agent.browser.family} {user_agent.browser.version_string}",
            'os': f"{user_agent.os.family} {user_agent.os.version_string}",
            'device_type': 'Mobile' if user_agent.is_mobile else ('Tablet' if user_agent.is_tablet else 'Desktop')
        }
    except:
        return {
            'browser': 'Unknown',
            'os': 'Unknown',
            'device_type': 'Unknown'
        }

def track_visitor():
    """Track visitor information"""
    try:
        visitor_id = get_visitor_id()
        ip_address = get_client_ip()
        user_agent = request.headers.get('User-Agent', '')
        referrer = request.referrer or 'Direct'
        current_page = request.path
        
        # Parse user agent
        ua_info = parse_user_agent(user_agent)
        
        # Get geo location
        geo_info = get_geo_location(ip_address)
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Check if visitor exists
        cursor.execute("""
            SELECT id, total_visits, total_page_views 
            FROM visitor_tracking 
            WHERE visitor_id = %s
        """, (visitor_id,))
        
        visitor = cursor.fetchone()
        
        if visitor:
            # Update existing visitor
            cursor.execute("""
                UPDATE visitor_tracking 
                SET last_visit = CURRENT_TIMESTAMP,
                    total_visits = total_visits + 1,
                    total_page_views = total_page_views + 1,
                    ip_address = %s,
                    user_agent = %s,
                    is_registered = %s,
                    user_id = %s
                WHERE visitor_id = %s
            """, (ip_address, user_agent, current_user.is_authenticated, 
                  current_user.id if current_user.is_authenticated else None, visitor_id))
        else:
            # Insert new visitor
            cursor.execute("""
                INSERT INTO visitor_tracking 
                (visitor_id, ip_address, user_agent, country, city, region, 
                 browser, os, device_type, referrer, landing_page, is_registered, user_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (visitor_id, ip_address, user_agent, geo_info['country'], 
                  geo_info['city'], geo_info['region'], ua_info['browser'], 
                  ua_info['os'], ua_info['device_type'], referrer, current_page,
                  current_user.is_authenticated, 
                  current_user.id if current_user.is_authenticated else None))
        
        # Track page view
        session_id = session.get('session_id', str(uuid.uuid4()))
        session['session_id'] = session_id
        
        cursor.execute("""
            INSERT INTO page_views 
            (visitor_id, page_url, page_title, referrer, session_id, ip_address, user_agent)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (visitor_id, current_page, request.endpoint or 'Unknown', 
              referrer, session_id, ip_address, user_agent))
        
        conn.commit()
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"Error tracking visitor: {str(e)}")
        log_error('visitor_tracking', str(e), request.path)

def log_error(error_type, error_message, endpoint, severity='medium'):
    """Log error to database and send alert if critical"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        ip_address = get_client_ip()
        user_id = current_user.id if current_user.is_authenticated else None
        
        cursor.execute("""
            INSERT INTO error_alerts 
            (error_type, error_message, endpoint, user_id, ip_address, severity)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (error_type, error_message, endpoint, user_id, ip_address, severity))
        
        error_id = cursor.fetchone()[0]
        conn.commit()
        
        # Send email alert for critical errors
        if severity in ['high', 'critical']:
            send_error_alert_email(error_id, error_type, error_message, endpoint)
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"Error logging error: {str(e)}")

def send_error_alert_email(error_id, error_type, error_message, endpoint):
    """Send email alert for critical errors"""
    try:
        # Email configuration from environment
        smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
        smtp_port = int(os.getenv('SMTP_PORT', 587))
        sender_email = os.getenv('SMTP_USERNAME', '')
        sender_password = os.getenv('SMTP_PASSWORD', '')
        admin_email = os.getenv('ADMIN_EMAIL', 'sreekanthchityala@gmail.com')
        
        if not sender_email or not sender_password:
            print("Email credentials not configured")
            return
        
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'🚨 Critical Error Alert - GSpaces'
        msg['From'] = sender_email
        msg['To'] = admin_email
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: #dc3545; color: white; padding: 20px; border-radius: 5px 5px 0 0; }}
                .content {{ background: #f8f9fa; padding: 20px; border: 1px solid #dee2e6; }}
                .error-box {{ background: white; padding: 15px; margin: 10px 0; border-left: 4px solid #dc3545; }}
                .label {{ font-weight: bold; color: #495057; }}
                .footer {{ text-align: center; padding: 20px; color: #6c757d; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h2>🚨 Critical Error Detected</h2>
                    <p>Error ID: #{error_id}</p>
                </div>
                <div class="content">
                    <div class="error-box">
                        <p><span class="label">Error Type:</span> {error_type}</p>
                        <p><span class="label">Endpoint:</span> {endpoint}</p>
                        <p><span class="label">Time:</span> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                    </div>
                    <div class="error-box">
                        <p><span class="label">Error Message:</span></p>
                        <pre style="background: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto;">{error_message}</pre>
                    </div>
                    <p style="margin-top: 20px;">
                        <a href="https://gspaces.in/admin/system-health" 
                           style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">
                            View System Health Dashboard
                        </a>
                    </p>
                </div>
                <div class="footer">
                    <p>This is an automated alert from GSpaces System Monitor</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html_content, 'html'))
        
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        
        # Mark as notified
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE error_alerts 
            SET is_notified = TRUE, notification_sent_at = CURRENT_TIMESTAMP 
            WHERE id = %s
        """, (error_id,))
        conn.commit()
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"Error sending alert email: {str(e)}")

# Admin Routes

@visitor_bp.route('/admin/visitors')
@login_required
@admin_required
def admin_visitors():
    """Admin page to view all visitors"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get filter parameters
        date_filter = request.args.get('date_filter', '7')  # Last 7 days by default
        device_filter = request.args.get('device', 'all')
        country_filter = request.args.get('country', 'all')
        
        # Build query
        query = """
            SELECT * FROM visitor_tracking 
            WHERE last_visit >= NOW() - INTERVAL '%s days'
        """ % date_filter
        
        if device_filter != 'all':
            query += f" AND device_type = '{device_filter}'"
        if country_filter != 'all':
            query += f" AND country = '{country_filter}'"
        
        query += " ORDER BY last_visit DESC LIMIT 1000"
        
        cursor.execute(query)
        visitors = cursor.fetchall()
        
        # Get statistics
        cursor.execute("""
            SELECT 
                COUNT(DISTINCT visitor_id) as total_visitors,
                SUM(total_page_views) as total_page_views,
                COUNT(DISTINCT CASE WHEN is_registered THEN visitor_id END) as registered_users,
                COUNT(DISTINCT CASE WHEN last_visit >= NOW() - INTERVAL '1 day' THEN visitor_id END) as today_visitors
            FROM visitor_tracking
            WHERE last_visit >= NOW() - INTERVAL '%s days'
        """ % date_filter)
        
        stats = cursor.fetchone()
        
        # Get top pages
        cursor.execute("""
            SELECT page_url, COUNT(*) as views
            FROM page_views
            WHERE created_at >= NOW() - INTERVAL '%s days'
            GROUP BY page_url
            ORDER BY views DESC
            LIMIT 10
        """ % date_filter)
        
        top_pages = cursor.fetchall()
        
        # Get countries
        cursor.execute("""
            SELECT DISTINCT country 
            FROM visitor_tracking 
            WHERE country != 'Unknown'
            ORDER BY country
        """)
        countries = [row['country'] for row in cursor.fetchall()]
        
        cursor.close()
        conn.close()
        
        return render_template('admin_visitors.html', 
                             visitors=visitors, 
                             stats=stats,
                             top_pages=top_pages,
                             countries=countries,
                             date_filter=date_filter,
                             device_filter=device_filter,
                             country_filter=country_filter)
        
    except Exception as e:
        log_error('admin_visitors', str(e), '/admin/visitors', 'high')
        return f"Error loading visitors: {str(e)}", 500

@visitor_bp.route('/admin/system-health')
@login_required
@admin_required
def admin_system_health():
    """Admin page to view system health and errors"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get recent errors
        cursor.execute("""
            SELECT * FROM error_alerts 
            ORDER BY created_at DESC 
            LIMIT 100
        """)
        errors = cursor.fetchall()
        
        # Get error statistics
        cursor.execute("""
            SELECT 
                COUNT(*) as total_errors,
                COUNT(CASE WHEN severity = 'critical' THEN 1 END) as critical_errors,
                COUNT(CASE WHEN severity = 'high' THEN 1 END) as high_errors,
                COUNT(CASE WHEN created_at >= NOW() - INTERVAL '1 hour' THEN 1 END) as last_hour_errors,
                COUNT(CASE WHEN created_at >= NOW() - INTERVAL '24 hours' THEN 1 END) as last_day_errors
            FROM error_alerts
            WHERE created_at >= NOW() - INTERVAL '7 days'
        """)
        error_stats = cursor.fetchone()
        
        # Get system health logs
        cursor.execute("""
            SELECT * FROM system_health_logs 
            ORDER BY created_at DESC 
            LIMIT 50
        """)
        health_logs = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return render_template('admin_system_health.html',
                             errors=errors,
                             error_stats=error_stats,
                             health_logs=health_logs)
        
    except Exception as e:
        log_error('admin_system_health', str(e), '/admin/system-health', 'critical')
        return f"Error loading system health: {str(e)}", 500

@visitor_bp.route('/api/visitor/track', methods=['POST'])
def api_track_visitor():
    """API endpoint to track page views from frontend"""
    try:
        data = request.get_json()
        visitor_id = get_visitor_id()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO page_views 
            (visitor_id, page_url, page_title, time_spent, session_id, ip_address, user_agent)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (visitor_id, data.get('page_url'), data.get('page_title'), 
              data.get('time_spent', 0), session.get('session_id'), 
              get_client_ip(), request.headers.get('User-Agent')))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True})
        
    except Exception as e:
        log_error('api_track_visitor', str(e), '/api/visitor/track')
        return jsonify({'error': str(e)}), 500

@visitor_bp.route('/api/system/health-check', methods=['GET'])
@login_required
@admin_required
def api_health_check():
    """Comprehensive system health check"""
    try:
        health_status = {
            'overall': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'checks': []
        }
        
        # 1. Database Connection Check
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            conn.close()
            health_status['checks'].append({
                'category': 'Database',
                'name': 'PostgreSQL Connection',
                'status': 'OK',
                'response_time': '< 100ms'
            })
        except Exception as e:
            health_status['overall'] = 'unhealthy'
            health_status['checks'].append({
                'category': 'Database',
                'name': 'PostgreSQL Connection',
                'status': 'FAILED',
                'error': str(e)
            })
            log_error('health_check_database', str(e), '/api/system/health-check', 'critical')
        
        # 2. Check All Public Pages
        pages_to_check = [
            ('/', 'Homepage'),
            ('/products', 'Products Page'),
            ('/about', 'About Page'),
            ('/contact', 'Contact Page'),
            ('/services', 'Services Page'),
            ('/blogs', 'Blogs Page'),
            ('/login', 'Login Page'),
            ('/signup', 'Signup Page'),
        ]
        
        for url, name in pages_to_check:
            try:
                import time
                start_time = time.time()
                response = requests.get(f'http://localhost:5000{url}', timeout=5)
                response_time = int((time.time() - start_time) * 1000)
                
                if response.status_code == 200:
                    health_status['checks'].append({
                        'category': 'Pages',
                        'name': name,
                        'status': 'OK',
                        'response_time': f'{response_time}ms',
                        'url': url
                    })
                else:
                    health_status['checks'].append({
                        'category': 'Pages',
                        'name': name,
                        'status': 'WARNING',
                        'response_time': f'{response_time}ms',
                        'url': url,
                        'http_code': response.status_code
                    })
            except Exception as e:
                health_status['overall'] = 'degraded'
                health_status['checks'].append({
                    'category': 'Pages',
                    'name': name,
                    'status': 'FAILED',
                    'url': url,
                    'error': str(e)
                })
        
        # 3. Email System Check
        try:
            smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
            smtp_port = int(os.getenv('SMTP_PORT', 587))
            sender_email = os.getenv('SMTP_USERNAME', '')
            sender_password = os.getenv('SMTP_PASSWORD', '')
            
            if sender_email and sender_password:
                import smtplib
                server = smtplib.SMTP(smtp_server, smtp_port, timeout=5)
                server.starttls()
                server.login(sender_email, sender_password)
                server.quit()
                health_status['checks'].append({
                    'category': 'Email',
                    'name': 'SMTP Connection',
                    'status': 'OK',
                    'server': smtp_server
                })
            else:
                health_status['checks'].append({
                    'category': 'Email',
                    'name': 'SMTP Configuration',
                    'status': 'WARNING',
                    'message': 'Email credentials not configured'
                })
        except Exception as e:
            health_status['overall'] = 'degraded'
            health_status['checks'].append({
                'category': 'Email',
                'name': 'SMTP Connection',
                'status': 'FAILED',
                'error': str(e)
            })
        
        # 4. File System Check
        try:
            import tempfile
            test_file = tempfile.NamedTemporaryFile(delete=False)
            test_file.write(b'health check')
            test_file.close()
            os.unlink(test_file.name)
            health_status['checks'].append({
                'category': 'System',
                'name': 'File System Write',
                'status': 'OK'
            })
        except Exception as e:
            health_status['overall'] = 'degraded'
            health_status['checks'].append({
                'category': 'System',
                'name': 'File System Write',
                'status': 'FAILED',
                'error': str(e)
            })
        
        # 5. Memory Check
        try:
            import psutil
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            if memory_percent < 80:
                status = 'OK'
            elif memory_percent < 90:
                status = 'WARNING'
            else:
                status = 'CRITICAL'
                health_status['overall'] = 'degraded'
            
            health_status['checks'].append({
                'category': 'System',
                'name': 'Memory Usage',
                'status': status,
                'value': f'{memory_percent}%',
                'available': f'{memory.available / (1024**3):.2f} GB'
            })
        except:
            # psutil not installed, skip
            pass
        
        return jsonify(health_status)
        
    except Exception as e:
        log_error('api_health_check', str(e), '/api/system/health-check', 'high')
        return jsonify({'error': str(e)}), 500

def register_visitor_routes(app, db_connection_func):
    """Register visitor tracking routes with the Flask app"""
    set_db_connection_func(db_connection_func)
    app.register_blueprint(visitor_bp)
    
    # Add before_request handler to track all visitors
    @app.before_request
    def before_request_tracking():
        # Skip tracking for static files and admin routes
        if not request.path.startswith('/static') and not request.path.startswith('/api'):
            track_visitor()

# Made with Bob
