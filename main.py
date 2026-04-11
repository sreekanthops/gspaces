import os
import sys
import random
import string
import psycopg2
from psycopg2 import Error
from psycopg2.extras import RealDictCursor # Import RealDictCursor
from flask_login import login_required, current_user
from flask import jsonify
import smtplib
import pymysql
import requests
from decimal import Decimal
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from flask import Flask, render_template_string
# Flask imports
from flask import (
    Flask, render_template, request, redirect, url_for, flash,
    session, jsonify, make_response, send_from_directory
)
from werkzeug.utils import secure_filename

# Flask-Login imports
from flask_login import (
    LoginManager, login_user, logout_user, login_required, current_user, UserMixin
)

# Google OAuth imports
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from authlib.integrations.flask_client import OAuth

# Email imports
from flask_mail import Mail, Message

# Password reset imports
from itsdangerous import URLSafeTimedSerializer

# Payment gateway imports
import razorpay
# Datetime import
from datetime import datetime

# Notification system import
from notifications import notify_new_order, notify_order_status_update

# --- CONFIGURATION ---
# Read from environment variables if available; fallback to development defaults.
# IMPORTANT: In production, NEVER hardcode sensitive information like this.
# Use environment variables (e.g., FLASK_APP_SECRET_KEY, DB_PASSWORD, RAZORPAY_KEY_ID)
# or a proper configuration management system.
from datetime import datetime, timedelta


# Flask App Configuration
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('FLASK_APP_SECRET_KEY', 'your_super_secret_fallback_key') # Replace with a strong, random key
app.config['SESSION_COOKIE_SECURE'] = os.getenv('SESSION_COOKIE_SECURE', 'False').lower() == 'true' # True in production
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

# Mail Configuration
app.config['MAIL_SERVER'] = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
app.config['MAIL_PORT'] = int(os.getenv('MAIL_PORT', 587))
app.config['MAIL_USE_TLS'] = os.getenv('MAIL_USE_TLS', 'True').lower() == 'true'
app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME', 'sri.chityala501@gmail.com') # Your email for sending
app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD', 'zupd zixc vvzp kptk') # Your app password
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_DEFAULT_SENDER', 'sri.chityala501@gmail.com')

mail = Mail(app)

# Serializer for password reset (uses app.config['SECRET_KEY'])
s = URLSafeTimedSerializer(app.config['SECRET_KEY'])

# Google OAuth Configuration
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "226581903418-3ed1eqsl14qlou4nmk2m9sdf6il1mluu.apps.googleusercontent.com")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "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")

# Admin Emails (for simple admin check)
ADMIN_EMAILS = {"sri.chityala501@gmail.com", "srichityala501@gmail.com", "sreekanth.chityala@gspaces.com"} # Replace with actual admin emails

# Database Configuration
DB_NAME = os.getenv("DB_NAME", "gspaces")
DB_USER = os.getenv("DB_USER", "sri")
DB_PASSWORD = os.getenv("DB_PASSWORD", "gspaces2025")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")



# File Uploads Configuration
UPLOAD_FOLDER = os.path.join('static', 'img', 'Products')
PROFILE_UPLOAD_FOLDER = os.path.join('static', 'img', 'profiles')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(PROFILE_UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['PROFILE_UPLOAD_FOLDER'] = PROFILE_UPLOAD_FOLDER

# Razorpay Configuration
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID", "rzp_live_R6wg6buSedSnTV") # Test Key ID
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET", "xeBC7q5tEirlDg4y4Tc3JEc3") # Test Key Secret

# Initialize Razorpay client
razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))


# --- FLASK-LOGIN SETUP ---
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login' # The endpoint name for the login page


# User class for Flask-Login
class User(UserMixin):
    def __init__(self, id, email, name, is_admin=False):
        self.id = id
        self.email = email
        self.name = name
        self.is_admin = is_admin

    def get_id(self):
        return str(self.id)

    def __repr__(self):
        return f"<User {self.id} {self.email}>"


@login_manager.user_loader
def load_user(user_id):
    conn = None
    try:
        conn = connect_to_db()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("SELECT id, email, name FROM users WHERE id = %s", (user_id,))
        user_data = cursor.fetchone()
        if user_data:
            # Check if the user's email is in ADMIN_EMAILS to set is_admin
            is_admin = user_data['email'] in ADMIN_EMAILS
            return User(id=user_data['id'], email=user_data['email'], name=user_data['name'], is_admin=is_admin)
        else:
            return None
    except Exception as e:
        print(f"Error loading user: {e}")
        return None
    finally:
        if conn:
            conn.close()

# --- GOOGLE OAUTH SETUP ---
oauth = OAuth(app)
google = oauth.register(
    name="google",
    client_id=GOOGLE_CLIENT_ID,
    client_secret=GOOGLE_CLIENT_SECRET,
    server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
    client_kwargs={"scope": "openid email profile"},
)

# --- DATABASE HELPERS ---
def connect_to_db():
    try:
        conn = psycopg2.connect(
            database=DB_NAME, user=DB_USER, password=DB_PASSWORD,
            host=DB_HOST, port=DB_PORT
        )
        return conn
    except Error as e:
        print(f"DB connection error: {e}")
        return None

def create_users_table(conn):
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                address VARCHAR(255),
                phone VARCHAR(50)
            );
        """)
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo VARCHAR(255)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line_2 VARCHAR(255)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(120)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(120)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS pincode VARCHAR(20)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(120)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS landmark VARCHAR(255)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS alternate_phone VARCHAR(50)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS company_name VARCHAR(255)")
        cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS gstin VARCHAR(30)")
        conn.commit()
    except Error as e:
        print(f"Error creating users table: {e}")

def create_products_table(conn):
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                category VARCHAR(100),
                price DECIMAL(10, 2),
                rating DECIMAL(2, 1),
                image_url VARCHAR(255),
                created_by VARCHAR(255)
            );
        """)
        conn.commit()
    except Error as e:
        print(f"Error creating products table: {e}")

def create_reviews_table(conn):
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS reviews (
                id SERIAL PRIMARY KEY,
                product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                username VARCHAR(255),
                rating INTEGER CHECK (rating BETWEEN 1 AND 5),
                comment TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
    except Error as e:
        print(f"Error creating reviews table: {e}")

def create_orders_table(conn):
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                user_email VARCHAR(255) NOT NULL,
                razorpay_order_id VARCHAR(255) UNIQUE NOT NULL,
                razorpay_payment_id VARCHAR(255),
                total_amount DECIMAL(10, 2) NOT NULL,
                status VARCHAR(50) NOT NULL,
                order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS status_code VARCHAR(50)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS status_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_name VARCHAR(255)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_phone VARCHAR(50)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_address_line_1 VARCHAR(255)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_address_line_2 VARCHAR(255)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_city VARCHAR(120)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_state VARCHAR(120)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_pincode VARCHAR(20)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_country VARCHAR(120)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_instructions TEXT")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS company_name VARCHAR(255)")
        cur.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS gstin VARCHAR(30)")
        cur.execute("UPDATE orders SET status_code = COALESCE(status_code, LOWER(REPLACE(status, ' ', '_')))")
        cur.execute("UPDATE orders SET status_updated_at = COALESCE(status_updated_at, order_date)")
        conn.commit()
    except Error as e:
        print(f"Error creating orders table: {e}")

def create_order_items_table(conn):
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS order_items (
                id SERIAL PRIMARY KEY,
                order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
                product_id INTEGER NOT NULL REFERENCES products(id),
                product_name VARCHAR(255) NOT NULL,
                quantity INTEGER NOT NULL,
                price_at_purchase DECIMAL(10, 2) NOT NULL,
                image_url VARCHAR(255)
            );
        """)
        cur.execute("ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_link VARCHAR(255)")
        conn.commit()
    except Error as e:
        print(f"Error creating order_items table: {e}")


# --- UTILITY FUNCTIONS ---
@app.template_filter('inr')
def inr_format(value):
    try:
        return f"{float(value):.2f}"
    except:
        return value

def get_catalogue_files():
    """Get list of files from the catalogue directory"""
    catalogue_dir = os.path.join(os.path.dirname(__file__), 'catalogue')
    files = []
    try:
        if os.path.exists(catalogue_dir):
            for filename in os.listdir(catalogue_dir):
                filepath = os.path.join(catalogue_dir, filename)
                # Only include actual files, not directories
                if os.path.isfile(filepath) and not filename.startswith('.'):
                    # Create a user-friendly display name
                    display_name = filename.rsplit('.', 1)[0]  # Remove extension
                    display_name = display_name.replace('_', ' ').replace('-', ' ')
                    files.append({
                        'name': filename,
                        'display_name': display_name
                    })
            # Sort files alphabetically by display name
            files.sort(key=lambda x: x['display_name'])
    except Exception as e:
        print(f"Error reading catalogue directory: {e}")
    return files

def upsert_user_from_google(google_sub, name, email):
    """Insert user if missing; return (id, name, email)."""
    conn = connect_to_db()
    if not conn:
        return None
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, name, email FROM users WHERE email = %s", (email,))
        user_data = cur.fetchone()
        if not user_data:
            # For Google users, we can use a dummy password or handle it differently
            # In a real app, you might distinguish between password and OAuth users
            dummy_password = "oauth_user_no_password_" + ''.join(random.choices(string.ascii_letters + string.digits, k=16))
            cur.execute("""
                INSERT INTO users (name, email, password)
                VALUES (%s, %s, %s)
                RETURNING id, name, email
            """, (name or email.split("@")[0], email, dummy_password))
            user_data = cur.fetchone()
            conn.commit()
        return user_data
    except Exception as e:
        print(f"upsert_user_from_google error: {e}")
        return None
    finally:
        if conn:
            cur.close()
            conn.close()

# --- ROUTES: MARKETING & LEGAL ---
@app.route('/privacy')
def privacy():
    return render_template('privacy.html')

@app.route('/terms')
def terms():
    return render_template('terms.html')

@app.route('/refund')
def refund_policy():
    return render_template('refund.html')

@app.route('/shipping')
def shipping_policy():
    return render_template('shipping.html')
# --- AUTHENTICATION ROUTES (Email/Password & Google) ---
@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')  # In production, use hashed passwords!

        conn = connect_to_db()
        if not conn:
            flash("Database connection failed during login.", "error")
            return render_template('login.html')

        cur = conn.cursor(cursor_factory=RealDictCursor)
        try:
            cur.execute("SELECT id, name, email, password FROM users WHERE email = %s", (email,))
            user_data = cur.fetchone()

            if user_data and user_data['password'] == password:  
                #  Create a User object for Flask-Login
                user_obj = User(
                    id=user_data['id'],
                    email=user_data['email'],
                    name=user_data['name'],
                    is_admin=(user_data['email'] in ADMIN_EMAILS)
                )

                #  Tell Flask-Login this user is logged in
                login_user(user_obj, remember=True)  # 'remember=True' keeps session active

                #  Store email in session (optional, for easier access)
                session['user_email'] = user_data['email']

                return redirect(url_for('index'))
            else:
                return render_template('login.html')

        except Error as e:
            print(f"Login DB error: {e}")
            return render_template('login.html')

        finally:
            if conn:
                cur.close()
                conn.close()

    return render_template('login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        try:
            name = request.form.get('name')
            email = request.form.get('email')
            password = request.form.get('password') # In production, use hashed passwords!

            conn = connect_to_db()
            if not conn:
                flash("Database connection failed.", "error")
                return redirect(url_for('signup'))
            cursor = conn.cursor(cursor_factory=RealDictCursor) # Use RealDictCursor

            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                return render_template('login.html')

            cursor.execute("""
                INSERT INTO users (name, email, password)
                VALUES (%s, %s, %s) RETURNING id, name, email
            """, (name, email, password)) # Password should be hashed
            new_user_data = cursor.fetchone()
            conn.commit()

            # Automatically log in the new user after signup
            if new_user_data:
                new_user_obj = User(id=new_user_data['id'], email=new_user_data['email'],
                                    name=new_user_data['name'], is_admin=(new_user_data['email'] in ADMIN_EMAILS))
                login_user(new_user_obj)
                flash("Signup successful! You have been logged in.", "success")
                return redirect(url_for('index'))
            else:
                flash("Signup failed. No user data returned after insert.", "error")
                return render_template('login.html')

        except Exception as e:
            print(f"ERROR: Signup error: {e}")
            flash("Signup failed due to a server error. Please try again.", "error")
            return render_template('login.html')
        finally:
            if conn:
                cursor.close()
                conn.close()
    return render_template('signup.html') # Ensure you have a signup.html template

@app.route('/logout')
@login_required
def logout():
    logout_user() # Flask-Login handles clearing the session
    return redirect(url_for('index'))

# --- GOOGLE OAUTH ROUTES ---
@app.route("/login/google")
def login_google():
    redirect_uri = url_for("auth_callback", _external=True)
    return google.authorize_redirect(redirect_uri)

@app.route("/auth/callback")
def auth_callback():
    try:
        token = google.authorize_access_token()
        user_info = google.parse_id_token(token)
        email = user_info.get("email")
        name = user_info.get("name") or (email.split("@")[0] if email else "User")

        if not email:
            flash("Google did not return an email. Cannot log you in.", "danger")
            return redirect(url_for("login"))

        # Upsert user and get their DB ID
        user_data_db = upsert_user_from_google(user_info.get('sub'), name, email)

        if user_data_db:
            user_obj = User(id=user_data_db['id'], email=user_data_db['email'],
                            name=user_data_db['name'], is_admin=(user_data_db['email'] in ADMIN_EMAILS))
            login_user(user_obj)
            flash(f"Welcome, {user_data_db['name']} (Google Login)!", "success")
            return redirect(url_for("index")) # Redirect to index or profile page
        else:
            flash("Failed to process Google login. Please try again.", "danger")
            return redirect(url_for("login"))

    except Exception as e:
        print(f"Google callback error: {e}")
        flash("Google login failed. Please try again.", "danger")
        return redirect(url_for("login"))

@app.route('/google_signin', methods=['GET', 'POST'])
def google_signin():
    # This route is typically for One Tap, which handles its own redirects or responses via JS.
    # The current implementation primarily handles the POST request from One Tap's credential response.
    if request.method == "GET":
        # If a GET request comes here, redirect to the full OAuth flow for clarity
        return redirect(url_for("login_google"))

    try:
        data = request.get_json(silent=True) or {}
        token = data.get('credential')
        if not token:
            return make_response(jsonify({"success": False, "message": "Missing credential"}), 400)

        idinfo = google_id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            GOOGLE_CLIENT_ID
        )

        if idinfo.get('iss') not in ('accounts.google.com', 'https://accounts.google.com'):
            return make_response(jsonify({"success": False, "message": "Invalid issuer"}), 400)

        email = idinfo.get('email')
        name = idinfo.get('name') or (email.split("@")[0] if email else "User")
        if not email:
            return make_response(jsonify({"success": False, "message": "Email missing in token"}), 400)

        user_data_db = upsert_user_from_google(idinfo.get('sub'), name, email)

        if user_data_db:
            user_obj = User(id=user_data_db['id'], email=user_data_db['email'],
                            name=user_data_db['name'], is_admin=(user_data_db['email'] in ADMIN_EMAILS))
            login_user(user_obj)
            return jsonify({"success": True, "redirect": url_for('index')})
        else:
            return make_response(jsonify({"success": False, "message": "Failed to process user"}), 500)

    except ValueError as e:
        print(f"Google token verify error: {e}")
        return make_response(jsonify({"success": False, "message": "Invalid token"}), 400)
    except Exception as e:
        print(f"google_signin server error: {e}")
        return make_response(jsonify({"success": False, "message": "Server error"}), 500)

# --- PASSWORD RESET ROUTES ---
@app.route('/forgot_password', methods=['GET', 'POST'])
def forgot_password():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        email = request.form['email']
        conn = None
        try:
            conn = connect_to_db()
            cur = conn.cursor()
            cur.execute("SELECT id FROM users WHERE email = %s", (email,))
            user = cur.fetchone()
            if user:
                token = s.dumps(email, salt='password-reset-salt')
                reset_url = url_for('reset_password', token=token, _external=True)

                msg = Message('Password Reset Request for GSpaces', recipients=[email])
                msg.body = f'''Hi,\n\nTo reset your password, click the link below:\n{reset_url}\n\nIf you didn't request this, please ignore.\n\nRegards,\nGSpaces Team\n'''
                mail.send(msg)
                flash('A password reset link has been sent to your email.', 'success')
            else:
                flash('No account found with that email address.', 'danger')
        except Exception as e:
            print(f"Forgot password error: {e}")
            flash('An error occurred while processing your request.', 'error')
        finally:
            if conn:
                cur.close()
                conn.close()
    return render_template('forgot_password.html')


@app.route('/reset_password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    try:
        email = s.loads(token, salt='password-reset-salt', max_age=3600) # Token valid for 1 hour
    except Exception:
        flash('The password reset link is invalid or has expired.', 'danger')
        return redirect(url_for('login'))

    if request.method == 'POST':
        new_password = request.form['password']
        confirm_password = request.form['confirm_password']

        if new_password != confirm_password:
            flash("New password and confirmation do not match.", "error")
            return render_template('reset_password.html', token=token) # Stay on the reset page

        conn = None
        try:
            conn = connect_to_db()
            cur = conn.cursor()
            # IMPORTANT: In production, hash the new_password before updating!
            cur.execute("UPDATE users SET password = %s WHERE email = %s", (new_password, email))
            conn.commit()
            flash('Your password has been reset successfully. Please log in with your new password.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            print(f"Reset password DB error: {e}")
            flash('An error occurred while resetting your password.', 'error')
        finally:
            if conn:
                cur.close()
                conn.close()

    return render_template('reset_password.html', token=token)

# --- HOME ROUTE ---
@app.route('/')
def index():
    conn = connect_to_db()
    product_list = []
    if conn:
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor) # Use RealDictCursor
            cursor.execute("""
                SELECT id, name, description, category, price, rating, image_url
                FROM products ORDER BY id;
            """)
            product_list = cursor.fetchall() # Fetches as list of dicts
        except Error as e:
            print(f"Error fetching products: {e}")
            flash("Error fetching products from database.", "error")
        finally:
            if conn:
                conn.close()
    else:
        flash("Error connecting to database to fetch products.", "error")

    # Get catalogue files
    catalogue_files = get_catalogue_files()

    # current_user is now available via Flask-Login
    user_display = current_user.name if current_user.is_authenticated else None
    return render_template('index.html',
                           products=product_list,
                           user=user_display,
                           catalogue_files=catalogue_files,
                           is_admin=current_user.is_authenticated and current_user.is_admin)

# --- CATALOGUE DOWNLOAD ROUTE ---
@app.route('/download_catalogue/<filename>')
def download_catalogue(filename):
    """Serve catalogue files for download"""
    try:
        catalogue_dir = os.path.join(os.path.dirname(__file__), 'catalogue')
        return send_from_directory(catalogue_dir, filename, as_attachment=True)
    except Exception as e:
        print(f"Error downloading catalogue file: {e}")
        flash("File not found.", "error")
        return redirect(url_for('index'))

ORDER_STATUS_LABELS = {
    'placed': 'Order placed',
    'confirmed': 'Confirmed',
    'packed': 'Packed',
    'shipped': 'Shipped',
    'out_for_delivery': 'Out for delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
}

ORDER_STATUS_FLOW = ['placed', 'confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered']


def normalize_order_status(status_code, legacy_status=None):
    normalized = (status_code or '').strip().lower().replace(' ', '_')
    if normalized in ORDER_STATUS_LABELS:
        return normalized

    legacy = (legacy_status or '').strip().lower()
    legacy_map = {
        'completed': 'confirmed',
        'pending': 'placed',
        'shipped': 'shipped',
        'delivered': 'delivered',
        'cancelled': 'cancelled'
    }
    return legacy_map.get(legacy, 'placed')


def build_tracking_timeline(status_code):
    if status_code == 'cancelled':
        return [{
            'label': ORDER_STATUS_LABELS['cancelled'],
            'state': 'current'
        }]

    current_index = ORDER_STATUS_FLOW.index(status_code) if status_code in ORDER_STATUS_FLOW else 0
    timeline = []
    for index, code in enumerate(ORDER_STATUS_FLOW):
        state = 'upcoming'
        if index < current_index:
            state = 'complete'
        elif index == current_index:
            state = 'current'
        timeline.append({
            'code': code,
            'label': ORDER_STATUS_LABELS[code],
            'state': state
        })
    return timeline


# --- USER PROFILE ROUTES ---
@app.route('/profile')
@login_required
def profile():
    user_email = current_user.email
    user_id = current_user.id
    user_details = {
        'name': current_user.name,
        'email': user_email,
        'address': '',
        'phone': '',
        'profile_photo': '',
        'address_line_2': '',
        'city': '',
        'state': '',
        'pincode': '',
        'country': 'India',
        'landmark': '',
        'alternate_phone': '',
        'company_name': '',
        'gstin': ''
    }
    user_orders = []
    conn = connect_to_db()
    if conn:
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT
                    name, email, address, phone, profile_photo, address_line_2,
                    city, state, pincode, country, landmark,
                    alternate_phone, company_name, gstin
                FROM users
                WHERE id = %s
                """,
                (user_id,)
            )
            rec = cursor.fetchone()
            if rec:
                user_details.update({
                    'name': rec.get('name') or current_user.name,
                    'email': rec.get('email') or user_email,
                    'address': rec.get('address') or '',
                    'phone': rec.get('phone') or '',
                    'profile_photo': rec.get('profile_photo') or '',
                    'address_line_2': rec.get('address_line_2') or '',
                    'city': rec.get('city') or '',
                    'state': rec.get('state') or '',
                    'pincode': rec.get('pincode') or '',
                    'country': rec.get('country') or 'India',
                    'landmark': rec.get('landmark') or '',
                    'alternate_phone': rec.get('alternate_phone') or '',
                    'company_name': rec.get('company_name') or '',
                    'gstin': rec.get('gstin') or ''
                })

            cursor.execute("""
                SELECT
                    o.id,
                    o.razorpay_order_id,
                    o.total_amount,
                    o.status,
                    o.status_code,
                    o.status_updated_at,
                    o.order_date,
                    json_agg(
                        json_build_object(
                            'product_id', oi.product_id,
                            'product_name', oi.product_name,
                            'quantity', oi.quantity,
                            'price_at_purchase', oi.price_at_purchase,
                            'image_url', oi.image_url,
                            'product_link', oi.product_link
                        )
                        ORDER BY oi.id
                    ) AS order_products
                FROM orders o
                JOIN order_items oi ON o.id = oi.order_id
                WHERE o.user_id = %s
                GROUP BY
                    o.id, o.razorpay_order_id, o.total_amount, o.status, o.status_code, o.status_updated_at, o.order_date
                ORDER BY o.order_date DESC;
            """, (user_id,))
            orders_data = cursor.fetchall()
            for order_row in orders_data:
                order_row['order_date'] = order_row['order_date'].strftime('%Y-%m-%d %H:%M:%S')
                order_status_code = normalize_order_status(order_row.get('status_code'), order_row.get('status'))
                order_row['status_code'] = order_status_code
                order_row['status_label'] = ORDER_STATUS_LABELS.get(order_status_code, 'Order placed')
                order_row['tracking_timeline'] = build_tracking_timeline(order_status_code)
                order_row['items'] = order_row.get('order_products') or []
                user_orders.append(order_row)
        except Exception as e:
            print(f"Error fetching profile data or orders: {e}")
            flash("We couldn't load your profile details right now.", "danger")
        finally:
            if conn:
                conn.close()

    return render_template(
        'profile.html',
        user=user_details['name'],
        user_details=user_details,
        user_orders=user_orders,
        order_status_labels=ORDER_STATUS_LABELS
    )
def get_next_product_id():
    # Example: Generate sequential ID or use DB auto-increment
    # return next ID from DB sequence
    from random import randint
    return randint(1000, 9999)  # Replace with actual logic

def save_product_to_db(product_id, name, category, rating, price, description, image_filename):
    # Example: Insert product metadata into your DB
    pass

def save_sub_image_record(product_id, filename, description):
    # Example: Insert sub-image record into your DB with product_id link
    pass

@app.route('/update_profile', methods=['POST'])
@login_required
def update_profile():
    user_id = current_user.id
    name = (request.form.get('name') or '').strip()
    phone = (request.form.get('phone') or '').strip()
    address = (request.form.get('address') or '').strip()
    address_line_2 = (request.form.get('address_line_2') or '').strip()
    city = (request.form.get('city') or '').strip()
    state = (request.form.get('state') or '').strip()
    pincode = (request.form.get('pincode') or '').strip()
    country = (request.form.get('country') or 'India').strip()
    landmark = (request.form.get('landmark') or '').strip()
    alternate_phone = (request.form.get('alternate_phone') or '').strip()
    company_name = (request.form.get('company_name') or '').strip()
    gstin = (request.form.get('gstin') or '').strip()
    profile_photo = request.files.get('profile_photo')

    if not name or not phone or not address or not city or not state or not pincode:
        flash("Please complete all required profile fields before saving.", "warning")
        return redirect(url_for('profile', _anchor='personal-details'))

    conn = connect_to_db()
    if not conn:
        flash("We couldn't save your profile right now. Please try again.", "danger")
        return redirect(url_for('profile', _anchor='personal-details'))

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT profile_photo FROM users WHERE id=%s", (user_id,))
        existing_user = cur.fetchone()
        profile_photo_path = existing_user.get('profile_photo') if existing_user else None

        if profile_photo and profile_photo.filename:
            filename = secure_filename(profile_photo.filename)
            ext = os.path.splitext(filename)[1].lower()
            allowed_exts = {'.png', '.jpg', '.jpeg', '.webp'}
            if ext not in allowed_exts:
                flash("Profile photo must be a PNG, JPG, JPEG, or WEBP image.", "warning")
                return redirect(url_for('profile', _anchor='personal-details'))

            profile_filename = f"user_{user_id}_{int(datetime.utcnow().timestamp())}{ext}"
            saved_path = os.path.join(app.config['PROFILE_UPLOAD_FOLDER'], profile_filename)
            profile_photo.save(saved_path)
            profile_photo_path = f"img/profiles/{profile_filename}"

        cur.execute("""
            UPDATE users
            SET
                name=%s,
                phone=%s,
                address=%s,
                profile_photo=%s,
                address_line_2=%s,
                city=%s,
                state=%s,
                pincode=%s,
                country=%s,
                landmark=%s,
                alternate_phone=%s,
                company_name=%s,
                gstin=%s
            WHERE id=%s
        """, (
            name, phone, address, profile_photo_path, address_line_2, city, state,
            pincode, country, landmark, alternate_phone, company_name, gstin, user_id
        ))
        conn.commit()
        cur.close()
        flash("Profile updated successfully.", "success")
    except Exception as e:
        print(f"Error updating profile: {e}")
        flash("We couldn't update your profile. Please try again.", "danger")
    finally:
        conn.close()

    return redirect(url_for('profile', _anchor='personal-details'))

@app.route('/update_profile_phone', methods=['POST'])
@login_required
def update_profile_phone():
    data = request.get_json()
    phone = data.get('phone')
    if not phone:
        return jsonify({"status": "error", "error": "Phone number missing"})

    conn = connect_to_db()
    if not conn:
        return jsonify({"status": "error", "error": "DB connection failed"})

    try:
        cur = conn.cursor()
        cur.execute("UPDATE users SET phone=%s WHERE id=%s", (phone, current_user.id))
        conn.commit()
        return jsonify({"status": "success"})
    except Exception as e:
        print(f"Error updating phone: {e}")
        return jsonify({"status": "error", "error": str(e)})
    finally:
        conn.close()

@app.route('/add_product', methods=['POST'])
@login_required
def add_product():
    if not current_user.is_admin:
        return jsonify({'success': False, 'message': 'Admins only.'}), 403

    try:
        name = request.form['name']
        category = request.form['category']
        rating = float(request.form['rating'])
        price = float(request.form['price'])
        description = request.form['description']
        created_by = current_user.email

        main_image = request.files.get('images')
        sub_images = request.files.getlist('sub_images')
        sub_descriptions = request.form.getlist('sub_descriptions')

        if not main_image or not main_image.filename:
            return jsonify({'success': False, 'message': 'Main image is required.'}), 400

        # --- Connect to PostgreSQL ---
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        cursor = conn.cursor()

        # Insert product (placeholder for image_url)
        cursor.execute("""
            INSERT INTO products (name, category, rating, price, description, image_url, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (name, category, rating, price, description, '', created_by))
        product_id = cursor.fetchone()[0]

        # Create folder for this product
        product_folder = os.path.join(app.config['UPLOAD_FOLDER'], str(product_id))
        os.makedirs(product_folder, exist_ok=True)

        # Save main image
        main_filename = f"{product_id}.jpg"
        main_path = os.path.join(product_folder, main_filename)
        main_image.save(main_path)
        main_image_url = f"img/Products/{product_id}/{main_filename}"

        cursor.execute("UPDATE products SET image_url=%s WHERE id=%s", (main_image_url, product_id))

        # Save sub images
        for idx, sub_img in enumerate(sub_images):
            if not sub_img.filename:
                continue
            sub_filename = f"{product_id}_sub{idx+1}.jpg"
            sub_path = os.path.join(product_folder, sub_filename)
            sub_img.save(sub_path)

            sub_image_url = f"img/Products/{product_id}/{sub_filename}"
            sub_desc = sub_descriptions[idx] if idx < len(sub_descriptions) else ''

            cursor.execute("""
                INSERT INTO product_sub_images (product_id, image_url, description)
                VALUES (%s, %s, %s)
            """, (product_id, sub_image_url, sub_desc))


        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'success': True, 'message': 'Product added successfully!'})

    except Exception as e:
        print(f"Add product error: {e}")
        return jsonify({'success': False, 'message': 'Error adding product.'}), 500


@app.route('/change_password', methods=['POST'])
@login_required # Protect this route
def change_password():
    # current_user is available
    user_id = current_user.id

    current_password = request.form.get('current_password')
    new_password = request.form.get('new_password')
    confirm_password = request.form.get('confirm_password')

    if new_password != confirm_password:
        flash("New password and confirm password do not match.", "error")
        return redirect(url_for('profile', _anchor='password-change')) # Redirect to correct tab

    conn = connect_to_db()
    if not conn:
        flash("Database connection failed.", "error")
        return redirect(url_for('profile'))

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor) # Use RealDictCursor
        cur.execute("SELECT password FROM users WHERE id = %s", (user_id,)) # Fetch by ID
        rec = cur.fetchone()

        if rec and rec['password'] == current_password:  # NOTE: Use password hashing (e.g., bcrypt) in production!
            cur.execute("UPDATE users SET password = %s WHERE id = %s",
                        (new_password, user_id))
            conn.commit()
            flash("Password changed successfully! You will be logged out for security.", "success")
            logout_user() # Log out after password change for security
            return redirect(url_for('login'))
        else:
            flash("Incorrect current password.", "error")
    except Error as e:
        print(f"Error changing password: {e}")
        flash("Failed to change password.", "error")
    finally:
        if conn:
            cur.close()
            conn.close()
    return redirect(url_for('profile', _anchor='password-change'))

@app.route('/edit_product/<int:product_id>', methods=['GET', 'POST'])
@login_required # Only logged-in users can edit products
def edit_product(product_id):
    if not current_user.is_admin:
        flash("Unauthorized. Admins only.", "warning")
        return redirect(url_for('index'))

    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        category = request.form['category']
        price = request.form['price']
        rating = request.form['rating']
        image_file = request.files.get('image')
        image_url = None
        if image_file and image_file.filename:
            filename = secure_filename(image_file.filename)
            image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            image_file.save(image_path)
            image_url = f'img/Products/{filename}'
        try:
            if image_url:
                cur.execute("""
                    UPDATE products
                       SET name=%s, description=%s, category=%s, price=%s, rating=%s, image_url=%s
                     WHERE id=%s
                """, (name, description, category, price, rating, image_url, product_id))
            else:
                cur.execute("""
                    UPDATE products
                       SET name=%s, description=%s, category=%s, price=%s, rating=%s
                     WHERE id=%s
                """, (name, description, category, price, rating, product_id))
            conn.commit()
            return redirect(url_for('index'))
        except Exception as e:
            print(f"Update product error: {e}")
            return redirect(url_for('index'))
        finally:
            if conn:
                cur.close()
                conn.close()

    try:
        cur.execute("SELECT id, name, description, category, price, rating, image_url FROM products WHERE id = %s", (product_id,))
        product = cur.fetchone() # Fetch as dict
        if not product:
            flash("Product not found.", "warning")
            return redirect(url_for('index'))
        return render_template('edit_product.html', product=product)
    except Exception as e:
        print(f"Fetch product error: {e}")
        flash("Error fetching product.", "error")
        return redirect(url_for('index'))
    finally:
        if conn:
            cur.close()
            conn.close()

@app.route('/delete_product/<int:product_id>', methods=['POST'])
@login_required # Only logged-in users can delete products
def delete_product(product_id):
    if not current_user.is_admin:
        flash("Unauthorized. Admins only.", "warning")
        return redirect(url_for('index'))

    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM products WHERE id = %s", (product_id,))
            conn.commit()
        except Error as e:
            print(f"Delete product error: {e}")
        finally:
            if conn:
                conn.close()
        return redirect(url_for('index'))
    return "Database connection failed", 500

# -----------------------
# DELETE MAIN IMAGE
# -----------------------
@app.route('/delete_main_image/<int:product_id>', methods=['POST'])
@login_required
def delete_main_image(product_id):
    if not current_user.is_admin:
        return redirect(url_for('index'))

    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("UPDATE products SET image_url = NULL WHERE id = %s", (product_id,))
            conn.commit()
            cur.close()
        finally:
            conn.close()

    return redirect(url_for('edit_product', product_id=product_id))

# -----------------------
# DELETE SUB-IMAGE
# -----------------------
@app.route('/delete_sub_image/<int:sub_image_id>', methods=['POST'])
@login_required
def delete_sub_image(sub_image_id):
    if not current_user.is_admin:
        return redirect(url_for('index'))

    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))

    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM product_sub_images WHERE id=%s", (sub_image_id,))
        conn.commit()
        cur.close()
    finally:
        conn.close()

    return redirect(request.referrer or url_for('index'))

# -----------------------
# EDIT SUB-IMAGE
# -----------------------
@app.route('/edit_sub_image/<int:sub_image_id>', methods=['POST'])
@login_required
def edit_sub_image(sub_image_id):
    if not current_user.is_admin:
        return redirect(url_for('index'))

    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))

    try:
        sub_image_file = request.files.get('sub_image')
        sub_description = request.form['sub_description']

        cur = conn.cursor()

        if sub_image_file and sub_image_file.filename:
            filename = secure_filename(sub_image_file.filename)
            path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            sub_image_file.save(path)
            image_url = f'img/Products/{filename}'
            cur.execute(
                "UPDATE product_sub_images SET image_url=%s, description=%s WHERE id=%s",
                (image_url, sub_description, sub_image_id)
            )
        else:
            cur.execute(
                "UPDATE product_sub_images SET description=%s WHERE id=%s",
                (sub_description, sub_image_id)
            )

        conn.commit()
        cur.close()
    finally:
        conn.close()

    return redirect(request.referrer or url_for('index'))


@app.route('/product/<int:product_id>', methods=['GET', 'POST'])
def product_detail(product_id):
    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))

    product, reviews, user_review, sub_images = None, [], None, []
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # --- Fetch Product ---
        cur.execute("""
            SELECT id, name, description, detailed_description, category, price, rating, image_url
            FROM products
            WHERE id = %s
        """, (product_id,))
        product = cur.fetchone()
        if not product:
            return redirect(url_for('index'))


        # --- Handle Review Submission ---
        if request.method == 'POST':
            if not current_user.is_authenticated:
                return redirect(url_for('login'))

            user_id = current_user.id
            user_name = current_user.name

            rating = request.form.get('rating', type=int)
            comment = request.form.get('comment')

            if not rating or not comment:
                flash("Provide both a rating and a comment.", "error")
            elif rating < 1 or rating > 5:
                flash("Rating must be between 1 and 5.", "error")
            else:
                cur.execute("SELECT id FROM reviews WHERE product_id = %s AND user_id = %s",
                            (product_id, user_id))
                existing = cur.fetchone()
                if existing:
                    cur.execute("""
                        UPDATE reviews
                           SET rating=%s, comment=%s, created_at=CURRENT_TIMESTAMP
                         WHERE id=%s
                    """, (rating, comment, existing['id']))
                else:
                    cur.execute("""
                        INSERT INTO reviews (product_id, user_id, username, rating, comment)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (product_id, user_id, user_name, rating, comment))
                conn.commit()
                return redirect(url_for('product_detail', product_id=product_id))

        # --- Fetch Reviews ---
        cur.execute("""
            SELECT username, rating, comment, created_at
              FROM reviews
             WHERE product_id = %s
          ORDER BY created_at DESC
        """, (product_id,))
        reviews_data = cur.fetchall()
        for r in reviews_data:
            r['created_at'] = r['created_at'].strftime('%Y-%m-%d %H:%M')
            reviews.append(r)

        # --- Check if Current User Already Reviewed ---
        if current_user.is_authenticated:
            cur.execute("""
                SELECT r.rating, r.comment
                  FROM reviews r
                  JOIN users u ON u.id = r.user_id
                 WHERE r.product_id = %s AND u.id = %s
            """, (product_id, current_user.id))
            ur = cur.fetchone()
            if ur:
                user_review = {'rating': ur['rating'], 'comment': ur['comment']}

        # --- Fetch Sub Images ---
        cur.execute("""
            SELECT id, image_url, description
              FROM product_sub_images
             WHERE product_id = %s
          ORDER BY id ASC
        """, (product_id,))
        sub_images = cur.fetchall()  # list of dicts

    except Error as e:
        print(f"product_detail error: {e}")
        return redirect(url_for('index'))
    finally:
        if conn:
            conn.close()

    return render_template(
        'product_detail.html',
        product=product,
        reviews=reviews,
        user_review=user_review,
        sub_images=sub_images
    )

@app.route('/edit_detailed_description/<int:product_id>', methods=['POST'])
@login_required
def edit_detailed_description(product_id):
    if not current_user.is_admin:
        return redirect(url_for('index'))

    detailed_description = request.form['detailed_description']

    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))

    try:
        cur = conn.cursor()
        cur.execute("""
            UPDATE products
               SET detailed_description = %s
             WHERE id = %s
        """, (detailed_description, product_id))
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for('product_detail', product_id=product_id))


@app.route('/add_sub_image/<int:product_id>', methods=['POST'])
@login_required
def add_sub_image(product_id):
    if not current_user.is_admin:
        return redirect(url_for('index'))

    conn = connect_to_db()
    if not conn:
        return redirect(url_for('index'))

    try:
        sub_image_file = request.files.get('sub_image')
        sub_description = request.form['sub_description']

        if not sub_image_file or not sub_image_file.filename:
            flash("Please select an image.", "warning")
            return redirect(request.referrer or url_for('edit_product', product_id=product_id))

        filename = secure_filename(sub_image_file.filename)
        path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        sub_image_file.save(path)
        image_url = f'img/Products/{filename}'

        cur = conn.cursor()
        cur.execute(
            "INSERT INTO product_sub_images (product_id, image_url, description) VALUES (%s, %s, %s)",
            (product_id, image_url, sub_description)
        )
        conn.commit()
        cur.close()
    finally:
        conn.close()

    return redirect(request.referrer or url_for('edit_product', product_id=product_id))


@app.route("/add_to_cart/<int:product_id>", methods=["POST", "GET"])
@login_required
def add_to_cart(product_id):
    try:
        conn = connect_to_db()
        cur = conn.cursor()

        # Check if product already exists in cart
        cur.execute(
            "SELECT quantity FROM cart WHERE user_id = %s AND product_id = %s",
            (current_user.id, product_id)
        )
        row = cur.fetchone()

        if row:
            # If exists - increment quantity
            cur.execute(
                "UPDATE cart SET quantity = quantity + 1 WHERE user_id = %s AND product_id = %s",
                (current_user.id, product_id)
            )
        else:
            # If not exists - insert new row
            cur.execute(
                "INSERT INTO cart (user_id, product_id, quantity) VALUES (%s, %s, %s)",
                (current_user.id, product_id, 1)
            )

        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error adding product to cart: {e}")
        flash("We couldn't add that item to your cart. Please try again.", "danger")
        return redirect(url_for("product_detail", product_id=product_id))

    flash("Added to cart.", "success")
    return redirect(url_for("cart"))

# ------------------ PAYMENT ROUTE ------------------ #

@app.route("/send_order", methods=["POST"])
@login_required
def send_order():
    try:
        # Example: getting cart/order data
        data = request.json or {}
        order_id = data.get("order_id", "N/A")
        total_amount = data.get("amount", 0)

        # Use plain text INR instead of INR symbol
        message_body = f"""
        Hello {current_user.name},

        Your order has been placed successfully 
        Order ID: {order_id}
        Total Amount: INR {total_amount}

        Thank you for shopping with us!
        """

        # ------------------ EMAIL ------------------ #
        msg = MIMEMultipart()
        msg["From"] = "no-reply@gspaces.in"
        msg["To"] = current_user.email
        msg["Subject"] = "Order Confirmation"

        # Attach as plain ASCII text (safe encoding)
        msg.attach(MIMEText(message_body, "plain", "utf-8"))

        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            # FIX: Use MAIL_USERNAME and MAIL_PASSWORD for consistency
            server.login(os.getenv("MAIL_USERNAME", "sri.chityala501@gmail.com"),
                        os.getenv("MAIL_PASSWORD", "zupd zixc vvzp kptk"))
            server.sendmail(msg["From"], [msg["To"]], msg.as_string())

        # ------------------ RESPONSE ------------------ #
        return jsonify({"status": "success", "message": "Order email sent successfully"}), 200

    except Exception as e:
        return jsonify({"status": "failed", "error": str(e)}), 500

    
@app.route('/remove_from_cart/<int:product_id>', methods=['POST', 'GET'])
@login_required
def remove_from_cart(product_id):
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM cart WHERE user_id=%s AND product_id=%s", (current_user.id, product_id))
            conn.commit()
            flash("Item removed from cart.", "info")
        except Exception as e:
            print(f"Error removing from cart: {e}")
            flash("We couldn't remove that item from your cart.", "danger")
        finally:
            conn.close()
    return redirect(url_for('cart'))


@app.route('/update_quantity/<int:product_id>/<string:action>', methods=['POST'])
@login_required
def update_quantity(product_id, action):
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            if action == 'increase':
                cur.execute("""
                    UPDATE cart SET quantity = quantity + 1
                    WHERE user_id = %s AND product_id = %s
                """, (current_user.id, product_id))
            elif action == 'decrease':
                cur.execute("""
                    UPDATE cart SET quantity = quantity - 1
                    WHERE user_id = %s AND product_id = %s AND quantity > 1
                """, (current_user.id, product_id))
                # If quantity goes below 1, delete item
                cur.execute("""
                    DELETE FROM cart WHERE user_id=%s AND product_id=%s AND quantity <= 0
                """, (current_user.id, product_id))
            conn.commit()
        except Exception as e:
            print(f"Error updating quantity: {e}")
            flash("We couldn't update your cart right now.", "danger")
        finally:
            conn.close()
    return redirect(url_for('cart'))


@app.template_filter()
def inr(value):
    """
    Format a Decimal or float as Indian Rupee string with 2 decimals.
    """
    if not isinstance(value, Decimal):
        value = Decimal(str(value))
    return "{:,.2f}".format(value)


COUNTDOWN_DURATION_MINUTES = None
countdown_start_time = None  # in-memory (replace with DB if needed)

@app.route("/update_discount", methods=["POST"])
def update_discount():
    global DISCOUNT_PERCENT, DISCOUNT_RATE
    if not current_user.is_authenticated or not current_user.is_admin:
        return "Unauthorized", 403

    data = request.get_json()
    try:
        new_discount = Decimal(data.get("discount_percent"))
        if new_discount < 0 or new_discount > 100:
            return "Invalid discount", 400

        # Save to DB
        save_discount_to_db(new_discount)

        # Update globals
        DISCOUNT_PERCENT = new_discount
        DISCOUNT_RATE = (Decimal("100") - DISCOUNT_PERCENT) / Decimal("100")

        return jsonify({"success": True, "discount_percent": str(DISCOUNT_PERCENT)})
    except Exception as e:
        return str(e), 400


@app.route("/get_discount")
def get_discount():
    return jsonify({"discount_percent": str(get_discount_from_db())})


def is_deal_active():
    global countdown_start_time, countdown_duration_minutes
    if countdown_start_time and countdown_duration_minutes:
        end_time = countdown_start_time + timedelta(minutes=countdown_duration_minutes)
        return datetime.utcnow() < end_time
    return False

def calculate_cart_totals(cart_items, coupon_discount=Decimal("0.00")):
    deal_active = is_deal_active()
    subtotal_after_discount = Decimal("0.00")
    original_subtotal = Decimal("0.00")
    deal_discount = Decimal("0.00")

    for item in cart_items:
        # Ensure price is a Decimal for math
        price = Decimal(item['price'])
        original_subtotal += price * item['quantity']

        if deal_active and DISCOUNT_RATE is not None:
            discounted_price = (price * DISCOUNT_RATE).quantize(Decimal('0.01'))
            # Add price difference to discount total
            deal_discount += (price - discounted_price) * item['quantity']
            
            item['display_price'] = discounted_price
            subtotal_after_discount += discounted_price * item['quantity']
        else:
            item['display_price'] = price
            subtotal_after_discount += price * item['quantity']

    # Apply coupon discount to subtotal
    subtotal_after_coupon = (subtotal_after_discount - coupon_discount).quantize(Decimal('0.01'))
    if subtotal_after_coupon < 0:
        subtotal_after_coupon = Decimal("0.00")
    
    gst_rate = Decimal('0.18')
    gst_amount = (subtotal_after_coupon * gst_rate).quantize(Decimal('0.01'))
    total_with_gst = (subtotal_after_coupon + gst_amount).quantize(Decimal('0.01'))

    return {
        "deal_active": deal_active,
        "subtotal": subtotal_after_discount, # Subtotal AFTER deal discount but BEFORE coupon
        "original_subtotal": original_subtotal, # Subtotal BEFORE any discount
        "deal_discount": deal_discount.quantize(Decimal('0.01')),
        "coupon_discount": coupon_discount.quantize(Decimal('0.01')),
        "subtotal_after_coupon": subtotal_after_coupon,
        "gst_amount": gst_amount,
        "total_with_gst": total_with_gst
    }


# --- Context processors for templates ---
@app.context_processor
def inject_discount():
    return dict(
        discount_percent=DISCOUNT_PERCENT,
        discount_rate=DISCOUNT_RATE,
        deal_active=is_deal_active()
    )

@app.context_processor
def inject_countdown_data():
    global countdown_start_time, countdown_duration_minutes

    if countdown_start_time and countdown_duration_minutes:
        end_time = countdown_start_time + timedelta(minutes=countdown_duration_minutes)
        now = datetime.utcnow()
        remaining = max(0, int((end_time - now).total_seconds()))
        return {"countdown_data": {"remaining": remaining}}

    return {"countdown_data": {"remaining": 0}}

@app.context_processor
def inject_cart_count():
    cart_count = 0
    if current_user.is_authenticated:
        conn = connect_to_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("SELECT COALESCE(SUM(quantity), 0) FROM cart WHERE user_id = %s", (current_user.id,))
                cart_count = cur.fetchone()[0]
            except Exception as e:
                print(f"Error fetching cart count: {e}")
            finally:
                conn.close()
    return dict(cart_count=cart_count)
# --- Countdown management routes ---
@app.route("/start_countdown_custom", methods=["POST"])
def start_countdown_custom():
    global countdown_start_time, countdown_duration_minutes
    if not current_user.is_authenticated or not current_user.is_admin:
        return "Unauthorized", 403

    data = request.get_json()
    minutes = data.get("minutes", 0)
    if minutes <= 0:
        return "Invalid duration", 400

    countdown_start_time = datetime.utcnow()
    countdown_duration_minutes = minutes
    return jsonify({"success": True, "remaining": minutes * 60})


@app.route("/stop_countdown", methods=["POST"])
def stop_countdown():
    global countdown_start_time
    if not current_user.is_authenticated or not current_user.is_admin:
        return "Unauthorized", 403
    countdown_start_time = None
    return redirect(url_for("index"))


@app.route("/countdown_status")
def countdown_status():
    global countdown_start_time, countdown_duration_minutes
    if countdown_start_time and countdown_duration_minutes:
        end_time = countdown_start_time + timedelta(minutes=countdown_duration_minutes)
        now = datetime.utcnow()
        remaining = max(0, int((end_time - now).total_seconds()))
        return {"active": True, "remaining": remaining}
    return {"active": False, "remaining": 0}

def get_discount_from_db():
    conn = connect_to_db()
    discount = Decimal("5")  # default
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("SELECT discount_percent FROM discount ORDER BY id DESC LIMIT 1")
            row = cur.fetchone()
            if row:
                discount = Decimal(row[0])
        except Exception as e:
            print(f"Error fetching discount from DB: {e}")
        finally:
            conn.close()
    return discount

def save_discount_to_db(discount):
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            # Clear old rows
            cur.execute("DELETE FROM discount")
            # Insert new discount
            cur.execute("INSERT INTO discount(discount_percent) VALUES (%s)", (str(discount),))
            conn.commit()
        except Exception as e:
            print(f"Error saving discount to DB: {e}")
        finally:
            conn.close()

# --- Config ---
DISCOUNT_PERCENT = get_discount_from_db()
DISCOUNT_RATE = (Decimal("100") - DISCOUNT_PERCENT) / Decimal("100")



cart_items = []
total_price = 0
gst_amount = 0
total_with_gst = 0
# --- COUPON MANAGEMENT ROUTES ---
@app.route('/admin/coupons')
@login_required
def admin_coupons():
    """Admin page to manage coupons"""
    if current_user.email not in ADMIN_EMAILS:
        flash("Access denied. Admin privileges required.", "danger")
        return redirect(url_for('index'))
    
    conn = connect_to_db()
    coupons = []
    
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT id, code, discount_type, discount_value, description, 
                       min_order_amount, max_discount_amount, is_active, 
                       usage_limit, times_used, valid_from, valid_until, created_at
                FROM coupons 
                ORDER BY created_at DESC
            """)
            coupons = cur.fetchall()
        except Exception as e:
            print(f"Error fetching coupons: {e}")
            flash("Error loading coupons.", "danger")
        finally:
            conn.close()
    
    return render_template('admin_coupons.html', coupons=coupons)

@app.route('/admin/coupons/add', methods=['POST'])
@login_required
def add_coupon():
    """Add a new coupon"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    try:
        code = request.form.get('code', '').strip().upper()
        discount_type = request.form.get('discount_type')
        discount_value = Decimal(request.form.get('discount_value', 0))
        description = request.form.get('description', '').strip()
        min_order_amount = Decimal(request.form.get('min_order_amount', 0))
        max_discount_amount = request.form.get('max_discount_amount')
        usage_limit = request.form.get('usage_limit')
        valid_until = request.form.get('valid_until')
        
        if not code or not discount_type or discount_value <= 0:
            flash("Invalid coupon data. Code, type, and value are required.", "danger")
            return redirect(url_for('admin_coupons'))
        
        conn = connect_to_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO coupons 
                    (code, discount_type, discount_value, description, min_order_amount, 
                     max_discount_amount, usage_limit, valid_until, created_by)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (code, discount_type, discount_value, description, min_order_amount,
                      max_discount_amount if max_discount_amount else None,
                      usage_limit if usage_limit else None,
                      valid_until if valid_until else None,
                      current_user.email))
                conn.commit()
                flash(f"Coupon '{code}' added successfully!", "success")
            except Exception as e:
                print(f"Error adding coupon: {e}")
                flash(f"Error adding coupon: {str(e)}", "danger")
            finally:
                conn.close()
    except Exception as e:
        flash(f"Error: {str(e)}", "danger")
    
    return redirect(url_for('admin_coupons'))

@app.route('/admin/coupons/toggle/<int:coupon_id>', methods=['POST'])
@login_required
def toggle_coupon(coupon_id):
    """Toggle coupon active status"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("UPDATE coupons SET is_active = NOT is_active WHERE id = %s", (coupon_id,))
            conn.commit()
            flash("Coupon status updated.", "success")
        except Exception as e:
            print(f"Error toggling coupon: {e}")
            flash("Error updating coupon.", "danger")
        finally:
            conn.close()
    
    return redirect(url_for('admin_coupons'))

@app.route('/admin/coupons/edit/<int:coupon_id>', methods=['POST'])
@login_required
def edit_coupon(coupon_id):
    """Edit an existing coupon"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    try:
        code = request.form.get('code', '').strip().upper()
        discount_type = request.form.get('discount_type')
        discount_value = Decimal(request.form.get('discount_value', 0))
        description = request.form.get('description', '').strip()
        min_order_amount = Decimal(request.form.get('min_order_amount', 0))
        max_discount_amount = request.form.get('max_discount_amount')
        usage_limit = request.form.get('usage_limit')
        valid_until = request.form.get('valid_until')
        
        if not code or not discount_type or discount_value <= 0:
            flash("Invalid coupon data. Code, type, and value are required.", "danger")
            return redirect(url_for('admin_coupons'))
        
        conn = connect_to_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE coupons 
                    SET code = %s, discount_type = %s, discount_value = %s, 
                        description = %s, min_order_amount = %s, 
                        max_discount_amount = %s, usage_limit = %s, valid_until = %s
                    WHERE id = %s
                """, (code, discount_type, discount_value, description, min_order_amount,
                      max_discount_amount if max_discount_amount else None,
                      usage_limit if usage_limit else None,
                      valid_until if valid_until else None,
                      coupon_id))
                conn.commit()
                flash(f"Coupon '{code}' updated successfully!", "success")
            except Exception as e:
                print(f"Error updating coupon: {e}")
                flash(f"Error updating coupon: {str(e)}", "danger")
            finally:
                conn.close()
    except Exception as e:
        flash(f"Error: {str(e)}", "danger")
    
    return redirect(url_for('admin_coupons'))

@app.route('/admin/coupons/get/<int:coupon_id>')
@login_required
def get_coupon(coupon_id):
    """Get coupon details for editing"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT id, code, discount_type, discount_value, description,
                       min_order_amount, max_discount_amount, usage_limit, 
                       valid_until
                FROM coupons WHERE id = %s
            """, (coupon_id,))
            coupon = cur.fetchone()
            if coupon:
                # Convert date to string for JSON
                if coupon['valid_until']:
                    coupon['valid_until'] = coupon['valid_until'].strftime('%Y-%m-%d')
                return jsonify({"status": "success", "coupon": dict(coupon)})
            return jsonify({"status": "error", "message": "Coupon not found"})
        except Exception as e:
            print(f"Error fetching coupon: {e}")
            return jsonify({"status": "error", "message": str(e)})
        finally:
            conn.close()
    return jsonify({"status": "error", "message": "Database connection error"})

# --- ADMIN ORDER MANAGEMENT ROUTES ---
@app.route('/admin/orders')
@login_required
def admin_orders():
    """Admin page to manage all orders"""
    if current_user.email not in ADMIN_EMAILS:
        flash("Access denied. Admin privileges required.", "danger")
        return redirect(url_for('index'))
    
    conn = connect_to_db()
    orders = []
    
    # Get filter parameters
    status_filter = request.args.get('status', 'all')
    search_query = request.args.get('search', '').strip()
    
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Build query based on filters
            query = """
                SELECT
                    o.id,
                    o.user_id,
                    o.user_email,
                    o.razorpay_order_id,
                    o.total_amount,
                    o.status,
                    o.status_code,
                    o.status_updated_at,
                    o.order_date,
                    o.shipping_name,
                    o.shipping_phone,
                    o.coupon_code,
                    o.coupon_discount,
                    COUNT(oi.id) AS items_count
                FROM orders o
                LEFT JOIN order_items oi ON oi.order_id = o.id
                WHERE 1=1
            """
            params = []
            
            # Add status filter
            if status_filter != 'all':
                query += " AND o.status_code = %s"
                params.append(status_filter)
            
            # Add search filter
            if search_query:
                query += " AND (CAST(o.id AS TEXT) LIKE %s OR o.user_email LIKE %s OR o.shipping_name LIKE %s)"
                search_pattern = f"%{search_query}%"
                params.extend([search_pattern, search_pattern, search_pattern])
            
            query += """
                GROUP BY o.id, o.user_id, o.user_email, o.razorpay_order_id, 
                         o.total_amount, o.status, o.status_code, o.status_updated_at, 
                         o.order_date, o.shipping_name, o.shipping_phone, 
                         o.coupon_code, o.coupon_discount
                ORDER BY o.order_date DESC
                LIMIT 100
            """
            
            cur.execute(query, params)
            orders = cur.fetchall()
            
            # Normalize status codes
            for order in orders:
                order['status_code'] = normalize_order_status(order.get('status_code'), order.get('status'))
                order['status_label'] = ORDER_STATUS_LABELS.get(order['status_code'], 'Order placed')
                
        except Exception as e:
            print(f"Error fetching orders: {e}")
            flash("Error loading orders.", "danger")
        finally:
            conn.close()
    
    return render_template(
        'admin_orders.html',
        orders=orders,
        status_filter=status_filter,
        search_query=search_query,
        order_statuses=ORDER_STATUS_LABELS,
        order_status_flow=ORDER_STATUS_FLOW
    )

@app.route('/admin/orders/update_status/<int:order_id>', methods=['POST'])
@login_required
def update_order_status(order_id):
    """Update order status"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    new_status = request.form.get('status')
    
    if not new_status or new_status not in ORDER_STATUS_LABELS:
        flash("Invalid status selected.", "danger")
        return redirect(url_for('admin_orders'))
    
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get old status and customer details before update
            cur.execute("""
                SELECT status_code, user_email, shipping_name, shipping_phone
                FROM orders
                WHERE id = %s
            """, (order_id,))
            order_data = cur.fetchone()
            old_status = order_data['status_code'] if order_data else None
            
            # Update order status
            cur.execute("""
                UPDATE orders
                SET status_code = %s,
                    status = %s,
                    status_updated_at = NOW()
                WHERE id = %s
            """, (new_status, ORDER_STATUS_LABELS[new_status], order_id))
            conn.commit()
            
            # Send notification to customer about status update
            if order_data:
                try:
                    notify_order_status_update(
                        order_id=order_id,
                        customer_name=order_data['shipping_name'],
                        customer_email=order_data['user_email'],
                        customer_phone=order_data['shipping_phone'],
                        old_status=old_status,
                        new_status=new_status,
                        status_label=ORDER_STATUS_LABELS[new_status]
                    )
                except Exception as e:
                    print(f"Error sending status update notification: {e}")
            
            flash(f"Order #{order_id} status updated to '{ORDER_STATUS_LABELS[new_status]}'", "success")
        except Exception as e:
            print(f"Error updating order status: {e}")
            flash("Error updating order status.", "danger")
        finally:
            conn.close()
    
    return redirect(url_for('admin_orders'))

@app.route('/admin/orders/view/<int:order_id>')
@login_required
def admin_view_order(order_id):
    """View detailed order information"""
    if current_user.email not in ADMIN_EMAILS:
        flash("Access denied. Admin privileges required.", "danger")
        return redirect(url_for('index'))
    
    conn = connect_to_db()
    order = None
    
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Fetch order details
            cur.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
            order = cur.fetchone()
            
            if order:
                # Fetch order items separately
                cur.execute("""
                    SELECT
                        product_id,
                        product_name,
                        quantity,
                        price_at_purchase,
                        image_url
                    FROM order_items
                    WHERE order_id = %s
                    ORDER BY id
                """, (order_id,))
                order_items = cur.fetchall()
                
                # Convert to dict and add items
                order = dict(order)
                order['order_items'] = order_items
                
                order['status_code'] = normalize_order_status(order.get('status_code'), order.get('status'))
                order['status_label'] = ORDER_STATUS_LABELS.get(order['status_code'], 'Order placed')
                order['tracking_timeline'] = build_tracking_timeline(order['status_code'])
        except Exception as e:
            print(f"Error fetching order details: {e}")
            flash("Error loading order details.", "danger")
        finally:
            conn.close()
    
    if not order:
        flash("Order not found.", "danger")
        return redirect(url_for('admin_orders'))
    
    return render_template(
        'admin_order_detail.html',
        order=order,
        order_statuses=ORDER_STATUS_LABELS,
        order_status_flow=ORDER_STATUS_FLOW
    )


@app.route('/admin/coupons/delete/<int:coupon_id>', methods=['POST'])
@login_required
def delete_coupon(coupon_id):
    """Delete a coupon"""
    if current_user.email not in ADMIN_EMAILS:
        return jsonify({"status": "error", "message": "Access denied"}), 403
    
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM coupons WHERE id = %s", (coupon_id,))
            conn.commit()
            flash("Coupon deleted successfully.", "success")
        except Exception as e:
            print(f"Error deleting coupon: {e}")
            flash("Error deleting coupon.", "danger")
        finally:
            conn.close()
    
    return redirect(url_for('admin_coupons'))

@app.route('/api/coupons/validate', methods=['POST'])
@login_required
def validate_coupon():
    """Validate a coupon code and return discount info"""
    data = request.get_json()
    code = data.get('code', '').strip().upper()
    cart_total = Decimal(str(data.get('cart_total', 0)))
    
    if not code:
        return jsonify({"status": "error", "message": "Please enter a coupon code"})
    
    conn = connect_to_db()
    if not conn:
        return jsonify({"status": "error", "message": "Database connection error"})
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT id, code, discount_type, discount_value, description,
                   min_order_amount, max_discount_amount, is_active,
                   usage_limit, times_used, valid_until
            FROM coupons 
            WHERE code = %s
        """, (code,))
        coupon = cur.fetchone()
        
        if not coupon:
            return jsonify({"status": "error", "message": "Invalid coupon code"})
        
        if not coupon['is_active']:
            return jsonify({"status": "error", "message": "This coupon is no longer active"})
        
        if coupon['valid_until'] and datetime.now() > coupon['valid_until']:
            return jsonify({"status": "error", "message": "This coupon has expired"})
        
        if coupon['usage_limit'] and coupon['times_used'] >= coupon['usage_limit']:
            return jsonify({"status": "error", "message": "This coupon has reached its usage limit"})
        
        if cart_total < Decimal(str(coupon['min_order_amount'])):
            return jsonify({
                "status": "error", 
                "message": f"Minimum order amount of ₹{coupon['min_order_amount']} required"
            })
        
        # Calculate discount
        if coupon['discount_type'] == 'percentage':
            discount_amount = (cart_total * Decimal(str(coupon['discount_value'])) / 100).quantize(Decimal('0.01'))
            if coupon['max_discount_amount']:
                discount_amount = min(discount_amount, Decimal(str(coupon['max_discount_amount'])))
        else:  # fixed
            discount_amount = Decimal(str(coupon['discount_value']))
        
        # Don't allow discount to exceed cart total
        discount_amount = min(discount_amount, cart_total)
        
        return jsonify({
            "status": "success",
            "message": f"Coupon applied! You saved ₹{discount_amount}",
            "coupon_code": coupon['code'],
            "discount_amount": float(discount_amount),
            "discount_type": coupon['discount_type'],
            "discount_value": float(coupon['discount_value']),
            "description": coupon['description']
        })
        
    except Exception as e:
        print(f"Error validating coupon: {e}")
        return jsonify({"status": "error", "message": "Error validating coupon"})
    finally:
        conn.close()

@app.route('/api/coupons/available')
@login_required
def get_available_coupons():
    """Get list of active coupons for display"""
    conn = connect_to_db()
    coupons = []
    
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT code, discount_type, discount_value, description, min_order_amount
                FROM coupons 
                WHERE is_active = TRUE 
                  AND (valid_until IS NULL OR valid_until > NOW())
                  AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_value DESC
                LIMIT 10
            """)
            coupons = cur.fetchall()
        except Exception as e:
            print(f"Error fetching available coupons: {e}")
        finally:
            conn.close()
    
    return jsonify({"status": "success", "coupons": coupons})

# --- Cart route ---
@app.route('/cart')
@login_required
def cart():
    conn = connect_to_db()
    cart_items = []
    user_details = {'phone': ''}

    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            # Fetch cart items
            cur.execute("""
                SELECT c.product_id AS id, c.quantity, p.name, p.price, p.image_url
                FROM cart c
                JOIN products p ON c.product_id = p.id
                WHERE c.user_id = %s
            """, (current_user.id,))
            cart_items = cur.fetchall()

            # Fetch user phone
            cur.execute("SELECT phone FROM users WHERE id=%s", (current_user.id,))
            rec = cur.fetchone()
            if rec and rec.get('phone'):
                user_details['phone'] = rec['phone']

        except Exception as e:
            print(f"Error fetching cart: {e}")
            flash("We couldn't load your cart right now.", "danger")
        finally:
            conn.close()

    totals = calculate_cart_totals(cart_items)

    # Razorpay order creation
    razorpay_order_id = None
    if totals["total_with_gst"] > 0:
        try:
            order_data = {
                "amount": int(totals["total_with_gst"] * 100),  # paise
                "currency": "INR",
                "payment_capture": 1
            }
            order = razorpay_client.order.create(order_data)
            razorpay_order_id = order['id']
        except Exception as e:
            print(f"Error creating Razorpay order: {e}")
            flash("We couldn't initialize payment right now. Please try again.", "danger")

    return render_template(
        "cart.html",
        cart_items=cart_items,
        subtotal=totals["subtotal"],
        original_subtotal=totals["original_subtotal"],
        gst_amount=totals["gst_amount"],
        total_with_gst=totals["total_with_gst"],
        user_details=user_details,
        deal_active=totals["deal_active"],
        razorpay_order_id=razorpay_order_id,
        razorpay_key=RAZORPAY_KEY_ID
    )

# --- Payment success route ---
@app.route('/payment/success', methods=['POST'])
@login_required
def payment_success():
    conn = None
    try:
        data = request.get_json()
        payment_id = data.get('razorpay_payment_id')
        order_id_from_razorpay = data.get('razorpay_order_id')
        signature = data.get('razorpay_signature')
        coupon_code = data.get('coupon_code')
        coupon_discount = Decimal(str(data.get('coupon_discount', 0)))

        razorpay_client.utility.verify_payment_signature({
            'razorpay_order_id': order_id_from_razorpay,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        })

        conn = connect_to_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            SELECT
                c.product_id,
                c.quantity,
                p.name,
                p.price,
                p.image_url
            FROM cart c
            JOIN products p ON c.product_id = p.id
            WHERE c.user_id = %s
        """, (current_user.id,))
        cart_items = cur.fetchall()
        if not cart_items:
            return jsonify({"status": "error", "error": "Your cart is empty."})

        totals = calculate_cart_totals(cart_items, coupon_discount)
        final_total = totals.get("total_with_gst")
        if final_total is None:
            raise Exception("Total calculation failed.")

        cur.execute("""
            SELECT
                name, email, phone, address, address_line_2,
                city, state, pincode, country, landmark,
                company_name, gstin
            FROM users
            WHERE id = %s
        """, (current_user.id,))
        user_profile = cur.fetchone() or {}

        shipping_name = user_profile.get('name') or current_user.name
        shipping_phone = user_profile.get('phone') or ''
        shipping_address_line_1 = user_profile.get('address') or ''
        shipping_address_line_2 = user_profile.get('address_line_2') or ''
        shipping_city = user_profile.get('city') or ''
        shipping_state = user_profile.get('state') or ''
        shipping_pincode = user_profile.get('pincode') or ''
        shipping_country = user_profile.get('country') or 'India'
        delivery_instructions = user_profile.get('landmark') or ''
        company_name = user_profile.get('company_name') or ''
        gstin = user_profile.get('gstin') or ''

        cur.execute("""
            INSERT INTO orders (
                user_id, user_email, razorpay_order_id, razorpay_payment_id,
                total_amount, status, status_code, status_updated_at, order_date,
                shipping_name, shipping_phone, shipping_address_line_1, shipping_address_line_2,
                shipping_city, shipping_state, shipping_pincode, shipping_country,
                delivery_instructions, company_name, gstin, coupon_code, coupon_discount
            )
            VALUES (
                %s, %s, %s, %s,
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s,
                %s, %s, %s, %s,
                %s, %s, %s, %s, %s
            ) RETURNING id
        """, (
            current_user.id, current_user.email, order_id_from_razorpay, payment_id,
            final_total, 'Confirmed', 'confirmed', datetime.now(), datetime.now(),
            shipping_name, shipping_phone, shipping_address_line_1, shipping_address_line_2,
            shipping_city, shipping_state, shipping_pincode, shipping_country,
            delivery_instructions, company_name, gstin, coupon_code, coupon_discount
        ))

        order_record = cur.fetchone()
        new_order_id = dict(order_record).get('id') if order_record else None
        if not new_order_id:
            raise Exception("Order insertion failed to return the ID.")

        for item in cart_items:
            price_to_save = item['display_price']
            product_link = url_for('product_detail', product_id=item['product_id'])

            cur.execute("""
                INSERT INTO order_items (
                    order_id, product_id, product_name, quantity,
                    price_at_purchase, image_url, product_link
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                new_order_id, item['product_id'], item['name'],
                item['quantity'], price_to_save, item['image_url'], product_link
            ))

        cur.execute("DELETE FROM cart WHERE user_id=%s", (current_user.id,))
        conn.commit()
        
        # Send notification to admin about new order
        try:
            notify_new_order(
                order_id=new_order_id,
                customer_name=shipping_name,
                customer_email=current_user.email,
                total_amount=final_total,
                items_count=len(cart_items)
            )
        except Exception as e:
            print(f"Error sending new order notification: {e}")

        sender = os.getenv("MAIL_USERNAME", "sri.chityala501@gmail.com")
        receiver = current_user.email
        discount_amount = totals.get('coupon_discount', Decimal('0.00'))
        order_status_label = ORDER_STATUS_LABELS['confirmed']

        items_html = "".join([
            f"""
            <tr>
                <td style='padding:12px;border-bottom:1px solid #e5e7eb;'>
                    <img src='{url_for('static', filename=item['image_url'], _external=True)}' width='56' style='border-radius:8px;object-fit:cover;'>
                </td>
                <td style='padding:12px;border-bottom:1px solid #e5e7eb;'>
                    <a href='{url_for('product_detail', product_id=item['product_id'], _external=True)}' style='color:#111827;text-decoration:none;font-weight:600;'>
                        {item['name']}
                    </a>
                </td>
                <td style='padding:12px;border-bottom:1px solid #e5e7eb;'>{item['quantity']}</td>
                <td style='padding:12px;border-bottom:1px solid #e5e7eb;'>INR {item['display_price']}</td>
                <td style='padding:12px;border-bottom:1px solid #e5e7eb;'>INR {item['display_price'] * item['quantity']}</td>
            </tr>
            """ for item in cart_items
        ])

        discount_row = ""
        if discount_amount > Decimal('0.00'):
            discount_row = f"""
            <tr>
                <td style="padding:8px 0;color:#b91c1c;">Deal discount</td>
                <td style="padding:8px 0;text-align:right;color:#b91c1c;">- INR {discount_amount}</td>
            </tr>
            """

        shipping_lines = [
            shipping_name,
            shipping_address_line_1,
            shipping_address_line_2,
            f"{shipping_city}, {shipping_state} - {shipping_pincode}" if shipping_city or shipping_state or shipping_pincode else "",
            shipping_country,
            f"Phone: {shipping_phone}" if shipping_phone else "",
        ]
        shipping_html = "<br>".join([line for line in shipping_lines if line])

        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"Order Confirmed - Invoice for Order #{new_order_id}"
        msg["From"] = sender
        msg["To"] = receiver

        html_body = f"""
        <html>
        <body style="margin:0;padding:0;background-color:#f5f5f5;font-family:Arial,sans-serif;color:#111827;">
            <div style="max-width:760px;margin:0 auto;padding:24px;">
                <div style="background:#111827;color:#fff;padding:24px 28px;border-radius:16px 16px 0 0;">
                    <h1 style="margin:0;font-size:28px;">GSpaces Invoice / Order Summary</h1>
                    <p style="margin:8px 0 0;color:#d1d5db;">Order #{new_order_id} - Payment ID {payment_id}</p>
                </div>
                <div style="background:#ffffff;padding:28px;border-radius:0 0 16px 16px;">
                    <p style="font-size:16px;margin-top:0;">Hello {current_user.name},</p>
                    <p style="line-height:1.7;color:#4b5563;">Your payment was successful and your order is now <strong>{order_status_label}</strong>. You can review status updates from your profile dashboard.</p>

                    <table style="width:100%;margin:24px 0;border-collapse:collapse;">
                        <tr>
                            <td style="width:50%;vertical-align:top;padding-right:16px;">
                                <h3 style="margin:0 0 8px;font-size:16px;">Shipping details</h3>
                                <p style="margin:0;color:#4b5563;line-height:1.7;">{shipping_html}</p>
                            </td>
                            <td style="width:50%;vertical-align:top;padding-left:16px;">
                                <h3 style="margin:0 0 8px;font-size:16px;">Invoice details</h3>
                                <p style="margin:0;color:#4b5563;line-height:1.7;">
                                    Order date: {datetime.now().strftime('%d %b %Y, %I:%M %p')}<br>
                                    Status: {order_status_label}<br>
                                    GSTIN: 36AORPG7724G1ZN
                                </p>
                            </td>
                        </tr>
                    </table>

                    <table style="width:100%;border-collapse:collapse;border:1px solid #e5e7eb;border-radius:12px;overflow:hidden;">
                        <thead>
                            <tr style="background:#f9fafb;text-align:left;">
                                <th style="padding:14px 12px;">Item</th>
                                <th style="padding:14px 12px;">Product</th>
                                <th style="padding:14px 12px;">Qty</th>
                                <th style="padding:14px 12px;">Unit price</th>
                                <th style="padding:14px 12px;">Line total</th>
                            </tr>
                        </thead>
                        <tbody>
                            {items_html}
                        </tbody>
                    </table>

                    <table style="width:320px;margin:24px 0 0 auto;border-collapse:collapse;">
                        <tr>
                            <td style="padding:8px 0;color:#4b5563;">Subtotal</td>
                            <td style="padding:8px 0;text-align:right;">INR {totals.get('original_subtotal', 0)}</td>
                        </tr>
                        {discount_row}
                        <tr>
                            <td style="padding:8px 0;color:#4b5563;">Taxable subtotal</td>
                            <td style="padding:8px 0;text-align:right;">INR {totals.get('subtotal', 0)}</td>
                        </tr>
                        <tr>
                            <td style="padding:8px 0;color:#4b5563;">GST (18%)</td>
                            <td style="padding:8px 0;text-align:right;">INR {totals.get('gst_amount', 0)}</td>
                        </tr>
                        <tr>
                            <td style="padding:12px 0;font-weight:700;border-top:1px solid #e5e7eb;">Total paid</td>
                            <td style="padding:12px 0;text-align:right;font-weight:700;border-top:1px solid #e5e7eb;">INR {totals.get('total_with_gst', 0)}</td>
                        </tr>
                    </table>

                    <p style="margin-top:32px;color:#4b5563;line-height:1.7;">
                        Need help with your order? Reply to this email or contact the GSpaces team. Product links above remain available from your profile order history as well.
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, os.getenv("MAIL_PASSWORD", "zupd zixc vvzp kptk"))
            server.sendmail(sender, receiver, msg.as_string())

        return jsonify({
            "status": "success",
            "message": "Payment received. Your order has been placed.",
            "order_id": new_order_id
        })

    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({"status": "error", "error": str(e)})
    finally:
        if conn:
            conn.close()

@app.route('/thankyou')
@login_required
def thankyou():
    order_id = request.args.get('order_id', type=int)
    order = None

    if order_id:
        conn = connect_to_db()
        if conn:
            try:
                cur = conn.cursor(cursor_factory=RealDictCursor)
                cur.execute("""
                    SELECT
                        o.id,
                        o.user_id,
                        o.total_amount,
                        o.status,
                        o.status_code,
                        o.order_date,
                        json_agg(
                            json_build_object(
                                'product_id', oi.product_id,
                                'product_name', oi.product_name,
                                'quantity', oi.quantity,
                                'price_at_purchase', oi.price_at_purchase,
                                'image_url', oi.image_url,
                                'product_link', oi.product_link
                            )
                            ORDER BY oi.id
                        ) AS items
                    FROM orders o
                    JOIN order_items oi ON oi.order_id = o.id
                    WHERE o.id = %s AND o.user_id = %s
                    GROUP BY o.id, o.user_id, o.total_amount, o.status, o.status_code, o.order_date
                """, (order_id, current_user.id))
                order = cur.fetchone()
                if order:
                    order['status_code'] = normalize_order_status(order.get('status_code'), order.get('status'))
                    order['status_label'] = ORDER_STATUS_LABELS.get(order['status_code'], 'Order placed')
                    order['tracking_timeline'] = build_tracking_timeline(order['status_code'])
            except Exception as e:
                print(f"Error loading thank you order: {e}")
            finally:
                conn.close()

    return render_template('thankyou.html', order_id=order_id, order=order)

# --- SITEMAP (for local testing, typically served by web server in prod) ---
@app.route('/sitemap.xml')
def serve_sitemap():
    if app.debug or os.environ.get('FLASK_ENV') == 'development':
        return send_from_directory(app.root_path, 'sitemap.xml')
    else:
        return redirect(url_for('static', filename='sitemap.xml'), code=301)


# --- APPLICATION BOOTSTRAP ---
if __name__ == '__main__':
    conn = connect_to_db()
    if conn:
        print("Database connection successful. Creating tables if they don't exist...")
        create_users_table(conn)
        create_products_table(conn)
        create_reviews_table(conn)
        create_orders_table(conn) # Create orders table
        create_order_items_table(conn) # Create order_items table
        conn.close()
        print("Tables checked/created. Starting Flask app.")
        app.run(host='0.0.0.0', port=5000, debug=True)
    else:
        print("Failed to connect to the database. Exiting.")


