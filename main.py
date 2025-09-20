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

# --- CONFIGURATION ---
# Read from environment variables if available; fallback to development defaults.
# IMPORTANT: In production, NEVER hardcode sensitive information like this.
# Use environment variables (e.g., FLASK_APP_SECRET_KEY, DB_PASSWORD, RAZORPAY_KEY_ID)
# or a proper configuration management system.
from datetime import datetime, timedelta

# Config
COUNTDOWN_DURATION_MINUTES = None
countdown_start_time = None  # in-memory (replace with DB if needed)


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
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Razorpay Configuration
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID", "rzp_live_R6wg6buSedSnTV") # Test Key ID
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET", "xeBC7q5tEirlDg4y4Tc3JEc3") # Test Key Secret

# Initialize Razorpay client
razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))


# --- FLASK-LOGIN SETUP ---
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login' # The endpoint name for the login page


@app.context_processor
def inject_countdown_data():
    global countdown_start_time, countdown_duration_minutes

    if countdown_start_time and countdown_duration_minutes:
        end_time = countdown_start_time + timedelta(minutes=countdown_duration_minutes)
        now = datetime.utcnow()
        remaining = max(0, int((end_time - now).total_seconds()))
        return {"countdown_data": {"remaining": remaining}}

    return {"countdown_data": {"remaining": 0}}

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
    return jsonify({"success": True, "remaining": minutes*60})


@app.route("/stop_countdown", methods=["POST"])
def stop_countdown():
    global countdown_start_time
    if not current_user.is_authenticated or not current_user.is_admin:
        return "Unauthorized", 403
    countdown_start_time = None
    return redirect(url_for("index"))



@app.route("/countdown_status")
def countdown_status():
    global countdown_start_time
    if countdown_start_time:
        end_time = countdown_start_time + timedelta(minutes=COUNTDOWN_DURATION_MINUTES)
        now = datetime.utcnow()
        remaining = max(0, int((end_time - now).total_seconds()))
        return {"active": True, "remaining": remaining}

    return {"active": False, "remaining": 0}

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
                # ✅ Create a User object for Flask-Login
                user_obj = User(
                    id=user_data['id'],
                    email=user_data['email'],
                    name=user_data['name'],
                    is_admin=(user_data['email'] in ADMIN_EMAILS)
                )

                # ✅ Tell Flask-Login this user is logged in
                login_user(user_obj, remember=True)  # 'remember=True' keeps session active

                # ✅ Store email in session (optional, for easier access)
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
            print(f"❌ Signup error: {e}")
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
                msg.body = f'''Hi,\n\nTo reset your password, click the link below:\n{reset_url}\n\nIf you didn’t request this, please ignore.\n\nRegards,\nGSpaces Team\n'''
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

    # current_user is now available via Flask-Login
    user_display = current_user.name if current_user.is_authenticated else None
    return render_template('index.html',
                           products=product_list,
                           user=user_display,
                           is_admin=current_user.is_authenticated and current_user.is_admin)

# --- USER PROFILE ROUTES ---
@app.route('/profile')
@login_required
def profile():
    # Obtain current user's ID and email via Flask-Login
    user_email = current_user.email
    user_id = current_user.id
    # Default user details in case DB fields are null
    user_details = {
        'name': current_user.name,
        'email': user_email,
        'address': 'Not provided',
        'phone': 'Not provided'
    }
    user_orders = []
    conn = connect_to_db()
    if conn:
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            # 1. Fetch user details
            cursor.execute(
                "SELECT name, email, address, phone FROM users WHERE id = %s",
                (user_id,)
            )
            rec = cursor.fetchone()
            if rec:
                user_details['name']    = rec['name']
                user_details['email']   = rec['email']
                user_details['address'] = rec['address'] or 'Not provided'
                user_details['phone']   = rec['phone']   or 'Not provided'
            # 2. Fetch orders with JSON aggregation of items, using a new alias 'order_products'
            cursor.execute("""
                SELECT
                    o.id,
                    o.razorpay_order_id,
                    o.total_amount,
                    o.status,
                    o.order_date,
                    json_agg(
                        json_build_object(
                            'product_id',      oi.product_id,
                            'product_name',    oi.product_name,
                            'quantity',        oi.quantity,
                            'price_at_purchase', oi.price_at_purchase,
                            'image_url',       oi.image_url
                        )
                    ) AS order_products -- CHANGED ALIAS HERE from 'items' to 'order_products'
                FROM orders o
                JOIN order_items oi ON o.id = oi.order_id
                WHERE o.user_id = %s
                GROUP BY
                    o.id, o.razorpay_order_id, o.total_amount, o.status, o.order_date
                ORDER BY o.order_date DESC;
            """, (user_id,))
            orders_data = cursor.fetchall()
            # 3. Format each order’s date and collect into list
            for order_row in orders_data:
                order_row['order_date'] = order_row['order_date'].strftime('%Y-%m-%d %H:%M:%S')
                
                # IMPORTANT: Take the data from 'order_products' and assign it to 'items'
                # This ensures the template still uses 'order.items' as expected.
                if 'order_products' in order_row:
                    order_row['items'] = order_row['order_products']
                else:
                    # Fallback in case 'order_products' is missing (shouldn't happen with correct SQL)
                    order_row['items'] = [] 
                    print(f"Warning: 'order_products' key missing in order_row: {order_row}")
                user_orders.append(order_row)
        except Exception as e:
            print(f"Error fetching profile data or orders: {e}")
            flash("Error loading profile data or orders.", "error")
        finally:
            if conn: # Ensure conn exists before closing
                conn.close()
    # Render the profile page with gathered data
    return render_template(
        'profile.html',
        user=user_details['name'],
        user_details=user_details,
        user_orders=user_orders
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
    name = request.form.get('name')
    phone = request.form.get('phone')
    address = request.form.get('address')

    conn = connect_to_db()
    if not conn:
        flash("Database connection failed.", "error")
        return redirect(url_for('profile'))

    try:
        cur = conn.cursor()
        cur.execute("""
            UPDATE users
            SET name=%s, phone=%s, address=%s
            WHERE id=%s
        """, (name, phone, address, user_id))
        conn.commit()
        cur.close()
        flash("Profile updated successfully.", "success")
    except Exception as e:
        print(f"Error updating profile: {e}")
        flash("Failed to update profile.", "error")
    finally:
        conn.close()

    return redirect(url_for('profile'))

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
            # If exists → increment quantity
            cur.execute(
                "UPDATE cart SET quantity = quantity + 1 WHERE user_id = %s AND product_id = %s",
                (current_user.id, product_id)
            )
        else:
            # If not exists → insert new row
            cur.execute(
                "INSERT INTO cart (user_id, product_id, quantity) VALUES (%s, %s, %s)",
                (current_user.id, product_id, 1)
            )

        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        flash(f"Error adding product to cart: {str(e)}")

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

        # Use plain text INR instead of ₹ symbol
        message_body = f"""
        Hello {current_user.name},

        Your order has been placed successfully ✅
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
            server.login(os.getenv("EMAIL_USER"), os.getenv("EMAIL_PASS"))
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
            flash("Error removing product from cart.", "error")
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
            flash("Error updating quantity.", "error")
        finally:
            conn.close()
    return redirect(url_for('cart'))

@app.route('/cart')
@login_required
def cart():
    conn = connect_to_db()
    cart_items = []
    total_price = 0
    gst_amount = 0
    total_with_gst = 0

    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT c.product_id AS id, c.quantity, p.name, p.price, p.image_url
                FROM cart c
                JOIN products p ON c.product_id = p.id
                WHERE c.user_id = %s
            """, (current_user.id,))
            cart_items = cur.fetchall()

            if cart_items:
                total_price = sum(float(item['price']) * item['quantity'] for item in cart_items)
                gst_amount = round(total_price * 0.18, 2)
                total_with_gst = round(total_price + gst_amount, 2)

        except Exception as e:
            print(f"Error fetching cart: {e}")
            flash("Error loading cart.", "error")
        finally:
            conn.close()

    razorpay_order_id = None
    if total_with_gst > 0:
        try:
            order_data = {
                "amount": int(total_with_gst * 100),
                "currency": "INR",
                "payment_capture": 1
            }
            order = razorpay_client.order.create(order_data)
            razorpay_order_id = order['id']
        except Exception as e:
            print(f"Error creating Razorpay order: {e}")
            flash("Error processing payment.", "error")

    return render_template("cart.html",
        cart_items=cart_items,
        total_price=total_price,
        gst_amount=gst_amount,
        total_with_gst=total_with_gst,
        razorpay_order_id=razorpay_order_id,
        razorpay_key=RAZORPAY_KEY_ID
    )


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

@app.route('/payment/success', methods=['POST'])
@login_required
def payment_success():
    conn = None
    try:
        data = request.get_json()  # get JSON from fetch
        payment_id = data.get('razorpay_payment_id')
        order_id_from_razorpay = data.get('razorpay_order_id')
        signature = data.get('razorpay_signature')

        # Verify Razorpay signature
        razorpay_client.utility.verify_payment_signature({
            'razorpay_order_id': order_id_from_razorpay,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        })

        conn = connect_to_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Fetch cart items
        cur.execute("""
            SELECT c.product_id, c.quantity, p.name, p.price, p.image_url
            FROM cart c
            JOIN products p ON c.product_id = p.id
            WHERE c.user_id = %s
        """, (current_user.id,))
        cart_items = cur.fetchall()
        if not cart_items:
            return jsonify({"status": "error", "error": "Cart is empty"})

        subtotal = sum(item['price'] * item['quantity'] for item in cart_items)
        gst_amount = round(subtotal * 0.18, 2)
        total_amount = round(subtotal + gst_amount, 2)


        # Insert order
        cur.execute("""
            INSERT INTO orders (user_id, user_email, razorpay_order_id, razorpay_payment_id, total_amount, status, order_date)
            VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id
        """, (current_user.id, current_user.email, order_id_from_razorpay, payment_id, total_amount, 'Completed', datetime.now()))
        new_order_id = cur.fetchone()['id']

        # Insert order items
        for item in cart_items:
            cur.execute("""
                INSERT INTO order_items (order_id, product_id, product_name, quantity, price_at_purchase, image_url)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (new_order_id, item['product_id'], item['name'], item['quantity'], item['price'], item['image_url']))

        # Clear cart
        cur.execute("DELETE FROM cart WHERE user_id=%s", (current_user.id,))
        conn.commit()

        # --- Build HTML email like old code ---
        sender = os.getenv("EMAIL_USER", "sri.chityala501@gmail.com")
        receiver = current_user.email

        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"Your GSpaces Order #{new_order_id} Confirmation"
        msg["From"] = sender
        msg["To"] = receiver

        items_html = "".join([
            f"""
            <tr>
                <td><img src='{url_for('static', filename=item['image_url'], _external=True)}' width='50'></td>
                <td>{item['name']}</td>
                <td>{item['quantity']}</td>
                <td>{item['price']} INR</td>
                <td>{item['price'] * item['quantity']} INR</td>
            </tr>
            """ for item in cart_items
        ])

        html_body = f"""
        <html>
        <body>
            <h2>Thank you for your order, {current_user.user}!</h2>
            <p>Your payment (<b>{payment_id}</b>) was successful. Here are your order details:</p>
            <table border="1" cellspacing="0" cellpadding="6" style="border-collapse: collapse; width: 100%;">
                <tr style="background-color:#f2f2f2;">
                    <th>Image</th>
                    <th>Product</th>
                    <th>Qty</th>
                    <th>Price</th>
                    <th>Subtotal</th>
                </tr>
                {items_html}
            </table>
            <h3>Subtotal: {subtotal} INR</h3>
            <h3>GST (18%): {gst_amount} INR</h3>
            <h2>Total: {total_amount} INR</h2>
            <p>We will process your order shortly. You can track your order on your GSpaces account.</p>
            <br>
            <p>Best Regards,<br>Team GSpaces</p>
        </body>
        </html>
        """
        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, os.getenv("EMAIL_PASS", "zupd zixc vvzp kptk"))
            server.sendmail(sender, receiver, msg.as_string())

        return jsonify({"status": "success", "message": "Payment successful, email sent"})

    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({"status": "error", "error": str(e)})
    finally:
        if conn:
            conn.close()

@app.route('/thankyou')
def thankyou():
    """
    Renders the thank you page after a successful payment.
    """
    return render_template('thankyou.html')

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
