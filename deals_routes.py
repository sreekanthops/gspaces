"""
Deals Management Routes
Handles admin panel for deals, discounts, and promotional campaigns
"""
from flask import render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import os

# Admin emails - should match main.py
ADMIN_EMAILS = [
    'sreekanth.chityala@gspaces.in',
    'gspaces2025@gmail.com'
]

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'gspaces'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'sri')
    )

def get_active_campaign():
    """Get the currently active campaign"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT * FROM deal_campaigns
            WHERE is_active = TRUE
            AND (end_time IS NULL OR end_time > NOW())
            ORDER BY created_at DESC
            LIMIT 1
        """)
        return cur.fetchone()
    finally:
        cur.close()
        conn.close()

def get_countdown_remaining(campaign):
    """Calculate remaining countdown time in seconds"""
    if not campaign or not campaign.get('end_time'):
        return 0
    
    now = datetime.now()
    end_time = campaign['end_time']
    
    if isinstance(end_time, str):
        end_time = datetime.fromisoformat(end_time)
    
    if end_time > now:
        return int((end_time - now).total_seconds())
    return 0

def calculate_product_discount(product_price, category_id=None):
    """
    Calculate discount for a product based on active deals
    Returns: (discounted_price, discount_percent, original_price)
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get active campaign
        campaign = get_active_campaign()
        if not campaign:
            return product_price, 0, product_price
        
        # Check global discount first
        cur.execute("""
            SELECT discount_percent, priority
            FROM global_discount
            WHERE campaign_id = %s AND is_active = TRUE
            ORDER BY priority DESC
            LIMIT 1
        """, (campaign['id'],))
        
        global_discount = cur.fetchone()
        
        # Check category discount
        category_discount = None
        if category_id:
            cur.execute("""
                SELECT discount_percent
                FROM category_discounts
                WHERE campaign_id = %s AND category_id = %s AND is_active = TRUE
                LIMIT 1
            """, (campaign['id'], category_id))
            category_discount = cur.fetchone()
        
        # Determine which discount to apply
        discount_percent = 0
        if global_discount and global_discount['priority'] > 0:
            discount_percent = float(global_discount['discount_percent'])
        elif category_discount:
            discount_percent = float(category_discount['discount_percent'])
        elif global_discount:
            discount_percent = float(global_discount['discount_percent'])
        
        if discount_percent > 0:
            discounted_price = product_price * (1 - discount_percent / 100)
            return round(discounted_price, 2), discount_percent, product_price
        
        return product_price, 0, product_price
        
    finally:
        cur.close()
        conn.close()

def register_deals_routes(app):
    """Register all deals management routes"""
    
    @app.route('/admin/deals')
    @login_required
    def admin_deals():
        """Display deals management page"""
        if current_user.email not in ADMIN_EMAILS:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            # Get active campaign
            active_campaign = get_active_campaign()
            countdown_remaining = get_countdown_remaining(active_campaign) if active_campaign else 0
            
            # Get category discounts
            if active_campaign:
                cur.execute("""
                    SELECT cd.*, c.name as category_name
                    FROM category_discounts cd
                    LEFT JOIN categories c ON cd.category_id = c.id
                    WHERE cd.campaign_id = %s
                    ORDER BY cd.category_name
                """, (active_campaign['id'],))
                category_discounts = cur.fetchall()
            else:
                category_discounts = []
            
            # Get global discount
            if active_campaign:
                cur.execute("""
                    SELECT * FROM global_discount
                    WHERE campaign_id = %s
                    ORDER BY priority DESC
                    LIMIT 1
                """, (active_campaign['id'],))
                global_discount = cur.fetchone()
            else:
                global_discount = None
            
            # Get all categories for dropdown
            cur.execute("""
                SELECT id, name FROM categories
                WHERE is_active = TRUE
                ORDER BY name
            """)
            categories = cur.fetchall()
            
            return render_template('admin_deals.html',
                                 active_campaign=active_campaign,
                                 countdown_remaining=countdown_remaining,
                                 category_discounts=category_discounts,
                                 global_discount=global_discount,
                                 categories=categories)
        except Exception as e:
            flash(f'Error loading deals: {str(e)}', 'danger')
            return redirect(url_for('admin_dashboard'))
        finally:
            cur.close()
            conn.close()
    
    @app.route('/admin/deals/campaign/create', methods=['POST'])
    @login_required
    def create_campaign():
        """Create a new deal campaign"""
        if current_user.email not in ADMIN_EMAILS:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        
        name = request.form.get('name', '').strip()
        description = request.form.get('description', '').strip()
        banner_text = request.form.get('banner_text', '').strip()
        countdown_duration = int(request.form.get('countdown_duration', 0))
        is_active = 'is_active' in request.form
        
        if not name or not banner_text:
            flash('Campaign name and banner text are required', 'danger')
            return redirect(url_for('admin_deals'))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Deactivate other campaigns if this one is active
            if is_active:
                cur.execute("UPDATE deal_campaigns SET is_active = FALSE WHERE is_active = TRUE")
            
            # Calculate end time if countdown is set
            end_time = None
            if countdown_duration > 0:
                end_time = datetime.now() + timedelta(seconds=countdown_duration * 60)
            
            cur.execute("""
                INSERT INTO deal_campaigns (name, description, banner_text, countdown_duration, is_active, start_time, end_time)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (name, description, banner_text, countdown_duration * 60, is_active, datetime.now(), end_time))
            
            conn.commit()
            flash('Campaign created successfully!', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error creating campaign: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_deals'))
    
    @app.route('/admin/deals/campaign/<int:campaign_id>/deactivate', methods=['POST'])
    @login_required
    def deactivate_campaign(campaign_id):
        """Deactivate a campaign"""
        if current_user.email not in ADMIN_EMAILS:
            return jsonify({'status': 'error', 'message': 'Unauthorized'}), 401
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("UPDATE deal_campaigns SET is_active = FALSE WHERE id = %s", (campaign_id,))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Campaign deactivated'})
        except Exception as e:
            conn.rollback()
            return jsonify({'status': 'error', 'message': str(e)}), 500
        finally:
            cur.close()
            conn.close()
    
    @app.route('/admin/deals/global-discount', methods=['POST'])
    @login_required
    def update_global_discount():
        """Update global discount settings"""
        if current_user.email not in ADMIN_EMAILS:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        
        discount_percent = float(request.form.get('discount_percent', 0))
        priority = int(request.form.get('priority', 1))
        is_active = 'is_active' in request.form
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Get active campaign
            campaign = get_active_campaign()
            if not campaign:
                flash('No active campaign. Please create a campaign first.', 'warning')
                return redirect(url_for('admin_deals'))
            
            # Check if global discount exists
            cur.execute("SELECT id FROM global_discount WHERE campaign_id = %s", (campaign['id'],))
            existing = cur.fetchone()
            
            if existing:
                cur.execute("""
                    UPDATE global_discount
                    SET discount_percent = %s, priority = %s, is_active = %s
                    WHERE campaign_id = %s
                """, (discount_percent, priority, is_active, campaign['id']))
            else:
                cur.execute("""
                    INSERT INTO global_discount (campaign_id, discount_percent, priority, is_active)
                    VALUES (%s, %s, %s, %s)
                """, (campaign['id'], discount_percent, priority, is_active))
            
            conn.commit()
            flash('Global discount updated successfully!', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error updating global discount: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_deals'))
    
    @app.route('/admin/deals/category-discount/add', methods=['POST'])
    @login_required
    def add_category_discount():
        """Add category-specific discount"""
        if current_user.email not in ADMIN_EMAILS:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        
        category_id = request.form.get('category_id')
        discount_percent = float(request.form.get('discount_percent', 0))
        is_active = 'is_active' in request.form
        
        if not category_id:
            flash('Please select a category', 'danger')
            return redirect(url_for('admin_deals'))
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            # Get active campaign
            campaign = get_active_campaign()
            if not campaign:
                flash('No active campaign. Please create a campaign first.', 'warning')
                return redirect(url_for('admin_deals'))
            
            # Get category name
            cur.execute("SELECT name FROM categories WHERE id = %s", (category_id,))
            category = cur.fetchone()
            
            if not category:
                flash('Invalid category', 'danger')
                return redirect(url_for('admin_deals'))
            
            # Check if discount already exists
            cur.execute("""
                SELECT id FROM category_discounts
                WHERE campaign_id = %s AND category_id = %s
            """, (campaign['id'], category_id))
            
            existing = cur.fetchone()
            
            if existing:
                flash('Discount for this category already exists. Please edit it instead.', 'warning')
                return redirect(url_for('admin_deals'))
            
            # Insert new discount
            cur.execute("""
                INSERT INTO category_discounts (campaign_id, category_id, category_name, discount_percent, is_active)
                VALUES (%s, %s, %s, %s, %s)
            """, (campaign['id'], category_id, category['name'], discount_percent, is_active))
            
            conn.commit()
            flash(f'Discount added for {category["name"]}!', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error adding category discount: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_deals'))
    
    @app.route('/admin/deals/category-discount/<int:discount_id>/delete', methods=['POST'])
    @login_required
    def delete_category_discount(discount_id):
        """Delete category discount"""
        if current_user.email not in ADMIN_EMAILS:
            return jsonify({'status': 'error', 'message': 'Unauthorized'}), 401
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("DELETE FROM category_discounts WHERE id = %s", (discount_id,))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Discount deleted'})
        except Exception as e:
            conn.rollback()
            return jsonify({'status': 'error', 'message': str(e)}), 500
        finally:
            cur.close()
            conn.close()
    
    @app.route('/admin/deals/countdown', methods=['POST'])
    @login_required
    def start_countdown():
        """Start or update countdown timer"""
        if current_user.email not in ADMIN_EMAILS:
            flash("Access denied. Admin privileges required.", "danger")
            return redirect(url_for('index'))
        
        duration_minutes = int(request.form.get('duration_minutes', 1440))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Get active campaign
            campaign = get_active_campaign()
            if not campaign:
                flash('No active campaign. Please create a campaign first.', 'warning')
                return redirect(url_for('admin_deals'))
            
            # Update countdown
            end_time = datetime.now() + timedelta(minutes=duration_minutes)
            cur.execute("""
                UPDATE deal_campaigns
                SET countdown_duration = %s, end_time = %s
                WHERE id = %s
            """, (duration_minutes * 60, end_time, campaign['id']))
            
            conn.commit()
            flash(f'Countdown started for {duration_minutes} minutes!', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error starting countdown: {str(e)}', 'danger')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_deals'))
    
    @app.route('/api/deals/active')
    def get_active_deals():
        """API endpoint to get active deals information"""
        try:
            campaign = get_active_campaign()
            if not campaign:
                return jsonify({
                    'status': 'success',
                    'has_active_deal': False
                })
            
            countdown_remaining = get_countdown_remaining(campaign)
            
            return jsonify({
                'status': 'success',
                'has_active_deal': True,
                'banner_text': campaign['banner_text'],
                'countdown_remaining': countdown_remaining
            })
        except Exception as e:
            return jsonify({
                'status': 'error',
                'message': str(e)
            }), 500

# Export the calculate_product_discount function for use in other modules
__all__ = ['register_deals_routes', 'calculate_product_discount', 'get_active_campaign', 'get_countdown_remaining']

# Made with Bob
