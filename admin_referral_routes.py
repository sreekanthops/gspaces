"""
Admin Routes for Referral Coupon Management
Add these routes to main.py
"""

from flask import render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal


def add_admin_referral_routes(app, connect_to_db, ADMIN_EMAILS):
    """Add admin referral coupon management routes"""
    
    def is_admin():
        """Check if current user is admin"""
        return current_user.is_authenticated and current_user.email in ADMIN_EMAILS
    
    @app.route('/admin/referral-coupons')
    @login_required
    def admin_referral_coupons():
        """Admin page to manage all referral coupons"""
        if not is_admin():
            flash("Access denied. Admin only.", "error")
            return redirect(url_for('index'))
        
        conn = connect_to_db()
        if not conn:
            flash("Database connection failed", "error")
            return redirect(url_for('index'))
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get all referral coupons with user info
            cur.execute("""
                SELECT 
                    rc.*,
                    u.name as user_name,
                    u.email as user_email
                FROM referral_coupons rc
                JOIN users u ON rc.user_id = u.id
                ORDER BY rc.created_at DESC
            """)
            coupons = cur.fetchall()
            
            # Get statistics
            cur.execute("""
                SELECT 
                    COUNT(*) as total_coupons,
                    COUNT(*) FILTER (WHERE is_active = true) as active_coupons,
                    SUM(times_used) as total_uses,
                    SUM(total_referral_earnings) as total_bonuses
                FROM referral_coupons
            """)
            stats = cur.fetchone()
            
            # Calculate total discounts given (from coupon_usage table)
            cur.execute("""
                SELECT COALESCE(SUM(discount_amount), 0) as total_discounts
                FROM coupon_usage
                WHERE coupon_code IN (SELECT coupon_code FROM referral_coupons)
            """)
            discount_stats = cur.fetchone()
            
            stats['total_discounts'] = float(discount_stats['total_discounts'] or 0)
            stats['total_bonuses'] = float(stats['total_bonuses'] or 0)
            stats['total_uses'] = int(stats['total_uses'] or 0)
            
            return render_template('admin_referral_coupons.html', 
                                 coupons=coupons, 
                                 stats=stats)
        
        except Exception as e:
            print(f"Error loading referral coupons: {e}")
            flash("Error loading referral coupons", "error")
            return redirect(url_for('index'))
        finally:
            conn.close()
    
    @app.route('/admin/referral-coupons/update', methods=['POST'])
    @login_required
    def update_referral_coupon():
        """Update referral coupon settings"""
        if not is_admin():
            return jsonify({'error': 'Access denied'}), 403
        
        conn = connect_to_db()
        if not conn:
            flash("Database connection failed", "error")
            return redirect(url_for('admin_referral_coupons'))
        
        try:
            coupon_id = request.form.get('coupon_id')
            discount_type = request.form.get('discount_type', 'fixed')
            discount_amount = request.form.get('discount_amount', 0)
            discount_percentage = request.form.get('discount_percentage', 0)
            referrer_bonus_type = request.form.get('referrer_bonus_type', 'fixed')
            referrer_bonus_amount = request.form.get('referrer_bonus_amount', 0)
            referral_bonus_percentage = request.form.get('referral_bonus_percentage', 0)
            min_order_amount = request.form.get('min_order_amount', 0)
            max_discount_amount = request.form.get('max_discount_amount') or None
            usage_limit = request.form.get('usage_limit') or None
            per_user_limit = request.form.get('per_user_limit', 1)
            first_order_only = request.form.get('first_order_only') == 'on'
            expires_at = request.form.get('expires_at') or None
            description = request.form.get('description', '')
            
            cur = conn.cursor()
            cur.execute("""
                UPDATE referral_coupons
                SET 
                    discount_type = %s,
                    discount_amount = %s,
                    discount_percentage = %s,
                    referrer_bonus_type = %s,
                    referrer_bonus_amount = %s,
                    referral_bonus_percentage = %s,
                    min_order_amount = %s,
                    max_discount_amount = %s,
                    usage_limit = %s,
                    per_user_limit = %s,
                    first_order_only = %s,
                    expires_at = %s,
                    description = %s
                WHERE id = %s
            """, (
                discount_type, discount_amount, discount_percentage,
                referrer_bonus_type, referrer_bonus_amount, referral_bonus_percentage,
                min_order_amount, max_discount_amount, usage_limit, per_user_limit,
                first_order_only, expires_at, description, coupon_id
            ))
            conn.commit()
            
            flash("Referral coupon updated successfully!", "success")
            return redirect(url_for('admin_referral_coupons'))
        
        except Exception as e:
            print(f"Error updating referral coupon: {e}")
            flash(f"Error updating coupon: {str(e)}", "error")
            return redirect(url_for('admin_referral_coupons'))
        finally:
            conn.close()
    
    @app.route('/admin/referral-coupons/toggle', methods=['POST'])
    @login_required
    def toggle_referral_coupon():
        """Toggle referral coupon active status"""
        if not is_admin():
            return jsonify({'error': 'Access denied'}), 403
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            data = request.get_json()
            coupon_id = data.get('coupon_id')
            is_active = data.get('is_active')
            
            cur = conn.cursor()
            cur.execute("""
                UPDATE referral_coupons
                SET is_active = %s
                WHERE id = %s
            """, (is_active, coupon_id))
            conn.commit()
            
            return jsonify({'success': True})
        
        except Exception as e:
            print(f"Error toggling referral coupon: {e}")
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()
    
    @app.route('/admin/referral-coupons/bulk-update', methods=['POST'])
    @login_required
    def bulk_update_referral_coupons():
        """Bulk update all referral coupons with same settings"""
        if not is_admin():
            return jsonify({'error': 'Access denied'}), 403
        
        conn = connect_to_db()
        if not conn:
            flash("Database connection failed", "error")
            return redirect(url_for('admin_referral_coupons'))
        
        try:
            discount_type = request.form.get('discount_type', 'fixed')
            discount_amount = request.form.get('discount_amount', 0)
            discount_percentage = request.form.get('discount_percentage', 0)
            referrer_bonus_type = request.form.get('referrer_bonus_type', 'fixed')
            referrer_bonus_amount = request.form.get('referrer_bonus_amount', 0)
            referral_bonus_percentage = request.form.get('referral_bonus_percentage', 0)
            
            cur = conn.cursor()
            cur.execute("""
                UPDATE referral_coupons
                SET
                    discount_type = %s,
                    discount_amount = %s,
                    discount_percentage = %s,
                    referrer_bonus_type = %s,
                    referrer_bonus_amount = %s,
                    referral_bonus_percentage = %s
                WHERE is_active = true
            """, (discount_type, discount_amount, discount_percentage,
                  referrer_bonus_type, referrer_bonus_amount, referral_bonus_percentage))
            
            rows_updated = cur.rowcount
            conn.commit()
            
            flash(f"✅ Successfully updated {rows_updated} active referral coupons!", "success")
            return redirect(url_for('admin_referral_coupons'))
        
        except Exception as e:
            print(f"Error bulk updating referral coupons: {e}")
            flash(f"❌ Error: {str(e)}", "error")
            return redirect(url_for('admin_referral_coupons'))
        finally:
            conn.close()

# Made with Bob
