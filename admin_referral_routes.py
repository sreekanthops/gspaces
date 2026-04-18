"""
Admin Routes for Referral Coupon Management
Add these routes to main.py
"""

from flask import render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
from email_helper import send_referral_update_email, send_bulk_referral_update_email


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
            
            # Get all referral coupons with user info and wallet balance
            # Try to get wallet balance, default to 0 if wallets table doesn't exist
            try:
                cur.execute("""
                    SELECT
                        rc.*,
                        u.name as user_name,
                        u.email as user_email,
                        COALESCE(w.balance, 0) as wallet_balance,
                        STRING_AGG(c.code, ', ' ORDER BY c.created_at DESC) as bonus_coupons
                    FROM referral_coupons rc
                    JOIN users u ON rc.user_id = u.id
                    LEFT JOIN wallets w ON u.id = w.user_id
                    LEFT JOIN coupons c ON u.id = c.user_id AND c.is_personal = TRUE
                    GROUP BY rc.id, rc.coupon_code, rc.user_id, rc.discount_type, rc.discount_amount,
                             rc.discount_percentage, rc.referrer_bonus_type, rc.referrer_bonus_amount,
                             rc.referral_bonus_percentage, rc.is_active, rc.times_used,
                             rc.total_referral_earnings, rc.created_at,
                             u.name, u.email, w.balance
                    ORDER BY rc.created_at DESC
                """)
                coupons = cur.fetchall()
            except Exception as wallet_error:
                # If wallets table doesn't exist, rollback and get coupons without wallet balance
                print(f"Wallets table not found, using default balance: {wallet_error}")
                conn.rollback()  # Rollback the failed transaction
                cur = conn.cursor(cursor_factory=RealDictCursor)  # Get new cursor
                cur.execute("""
                    SELECT
                        rc.*,
                        u.name as user_name,
                        u.email as user_email,
                        0 as wallet_balance,
                        STRING_AGG(c.code, ', ' ORDER BY c.created_at DESC) as bonus_coupons
                    FROM referral_coupons rc
                    JOIN users u ON rc.user_id = u.id
                    LEFT JOIN coupons c ON u.id = c.user_id AND c.is_personal = TRUE
                    GROUP BY rc.id, rc.coupon_code, rc.user_id, rc.discount_type, rc.discount_amount,
                             rc.discount_percentage, rc.referrer_bonus_type, rc.referrer_bonus_amount,
                             rc.referral_bonus_percentage, rc.is_active, rc.times_used,
                             rc.total_referral_earnings, rc.created_at,
                             u.name, u.email
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
        """Update referral coupon settings and optionally adjust wallet balance"""
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
            
            # Wallet adjustment fields
            wallet_adjustment = request.form.get('wallet_adjustment', '').strip()
            wallet_reason = request.form.get('wallet_reason', '').strip()
            
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get user_id, user info, and coupon code for this coupon
            cur.execute("""
                SELECT rc.user_id, rc.coupon_code, u.email, u.name
                FROM referral_coupons rc
                JOIN users u ON rc.user_id = u.id
                WHERE rc.id = %s
            """, (coupon_id,))
            coupon_user = cur.fetchone()
            
            if not coupon_user:
                flash("Coupon not found", "error")
                return redirect(url_for('admin_referral_coupons'))
            
            user_id = coupon_user['user_id']
            user_email = coupon_user['email']
            user_name = coupon_user['name']
            referral_code = coupon_user['coupon_code']
            
            # Update referral coupon
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
            
            # Send email notification about referral coupon update
            referral_updated = True
            try:
                # Get the updated coupon details for email
                friend_discount = f"₹{discount_amount}" if discount_type == 'fixed' else f"{discount_percentage}%"
                owner_bonus = f"₹{referrer_bonus_amount}" if referrer_bonus_type == 'fixed' else f"{referral_bonus_percentage}%"
                
                send_referral_update_email(
                    user_email=user_email,
                    user_name=user_name,
                    referral_code=referral_code,
                    friend_discount=friend_discount,
                    owner_bonus=owner_bonus,
                    referral_updated=True
                )
            except Exception as email_error:
                print(f"Failed to send referral update email: {email_error}")
                # Don't fail the whole operation if email fails
            
            # Handle wallet adjustment if provided
            wallet_updated = False
            new_balance = None
            if wallet_adjustment and float(wallet_adjustment) != 0:
                try:
                    adjustment_amount = float(wallet_adjustment)
                    
                    # Ensure wallet exists for user
                    cur.execute("""
                        INSERT INTO wallets (user_id, balance)
                        VALUES (%s, 0)
                        ON CONFLICT (user_id) DO NOTHING
                    """, (user_id,))
                    
                    # Add to current balance (not replace)
                    cur.execute("""
                        UPDATE wallets
                        SET balance = balance + %s
                        WHERE user_id = %s
                        RETURNING balance
                    """, (adjustment_amount, user_id))
                    
                    result = cur.fetchone()
                    new_balance = float(result['balance']) if result else 0
                    
                    # Determine transaction type based on positive/negative adjustment
                    transaction_type = 'admin_credit' if adjustment_amount > 0 else 'admin_debit'
                    
                    # Create wallet transaction record with balance_after
                    transaction_description = wallet_reason if wallet_reason else f"Admin adjustment by {current_user.email}"
                    cur.execute("""
                        INSERT INTO wallet_transactions
                        (user_id, transaction_type, amount, balance_after, description, created_at)
                        VALUES (%s, %s, %s, %s, %s, NOW())
                    """, (user_id, transaction_type, abs(adjustment_amount), new_balance, transaction_description))
                    
                    wallet_updated = True
                    
                    # Send email notification about wallet adjustment
                    try:
                        send_referral_update_email(
                            user_email=user_email,
                            user_name=user_name,
                            referral_code=referral_code,
                            wallet_adjustment=True,
                            new_wallet_balance=new_balance,
                            wallet_adjustment_reason=transaction_description
                        )
                    except Exception as email_error:
                        print(f"Failed to send wallet adjustment email: {email_error}")
                        # Don't fail the whole operation if email fails
                    
                except ValueError:
                    flash("Invalid wallet adjustment amount", "error")
                    return redirect(url_for('admin_referral_coupons'))
                except Exception as wallet_error:
                    print(f"Error adjusting wallet: {wallet_error}")
                    flash(f"Coupon updated but wallet adjustment failed: {str(wallet_error)}", "warning")
                    conn.commit()  # Commit the coupon update at least
                    return redirect(url_for('admin_referral_coupons'))
            
            # Handle personal coupon creation if provided
            personal_coupon_created = False
            personal_coupon_code = None
            personal_discount_type = request.form.get('personal_discount_type', '').strip()
            
            if personal_discount_type in ['fixed', 'percentage']:
                try:
                    import random
                    import string
                    from datetime import datetime, timedelta
                    
                    # Get discount values
                    if personal_discount_type == 'fixed':
                        personal_discount_amount = float(request.form.get('personal_discount_amount', 0))
                        personal_discount_percentage = 0
                    else:
                        personal_discount_amount = 0
                        personal_discount_percentage = float(request.form.get('personal_discount_percentage', 0))
                    
                    personal_reason = request.form.get('personal_coupon_reason', '').strip()
                    
                    # Generate unique coupon code: BONUS_USERNAME_RANDOM
                    username_part = user_name.upper().replace(' ', '')[:8]
                    random_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
                    personal_coupon_code = f"BONUS_{username_part}_{random_part}"
                    
                    # Set expiry to 3 months from now
                    expiry_date = datetime.now() + timedelta(days=90)
                    
                    # Create personal coupon in coupons table
                    cur.execute("""
                        INSERT INTO coupons
                        (code, discount_type, discount_value, description, user_id, is_personal,
                         is_active, valid_until, created_by, created_at)
                        VALUES (%s, %s, %s, %s, %s, TRUE, TRUE, %s, %s, NOW())
                    """, (
                        personal_coupon_code,
                        personal_discount_type,
                        personal_discount_amount if personal_discount_type == 'fixed' else personal_discount_percentage,
                        personal_reason or f"Personal coupon for {user_name}",
                        user_id,
                        expiry_date,
                        current_user.email
                    ))
                    
                    personal_coupon_created = True
                    
                    # Send email notification about personal coupon
                    try:
                        from email_helper import send_personal_coupon_email
                        discount_text = f"₹{personal_discount_amount}" if personal_discount_type == 'fixed' else f"{personal_discount_percentage}%"
                        send_personal_coupon_email(
                            user_email=user_email,
                            user_name=user_name,
                            coupon_code=personal_coupon_code,
                            discount=discount_text,
                            expiry_date=expiry_date.strftime('%B %d, %Y'),
                            reason=personal_reason
                        )
                    except Exception as email_error:
                        print(f"Failed to send personal coupon email: {email_error}")
                        # Don't fail the whole operation if email fails
                    
                except Exception as personal_coupon_error:
                    print(f"Error creating personal coupon: {personal_coupon_error}")
                    flash(f"Coupon updated but personal coupon creation failed: {str(personal_coupon_error)}", "warning")
                    conn.commit()  # Commit the referral coupon update at least
                    return redirect(url_for('admin_referral_coupons'))
            
            conn.commit()
            
            # Success message
            messages = []
            messages.append("Referral coupon updated successfully!")
            
            if wallet_updated:
                messages.append(f"Wallet balance adjusted by ₹{wallet_adjustment} (New balance: ₹{new_balance:.2f})")
            
            if personal_coupon_created:
                messages.append(f"Personal coupon '{personal_coupon_code}' created and sent to user")
            
            flash(" | ".join(messages), "success")
            
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
            
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get affected users before update
            cur.execute("""
                SELECT u.id, u.name, u.email, rc.coupon_code
                FROM referral_coupons rc
                JOIN users u ON rc.user_id = u.id
                WHERE rc.is_active = true
            """)
            affected_users = cur.fetchall()
            
            # Update coupons
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
            
            # Prepare email data
            friend_discount = f"₹{int(float(discount_amount))}" if discount_type == 'fixed' else f"{discount_percentage}%"
            owner_bonus = f"₹{int(float(referrer_bonus_amount))}" if referrer_bonus_type == 'fixed' else f"{referral_bonus_percentage}%"
            
            # Send emails to all affected users
            users_data = [{
                'email': user['email'],
                'name': user['name'],
                'referral_code': user['coupon_code'],
                'friend_discount': friend_discount,
                'owner_bonus': owner_bonus
            } for user in affected_users]
            
            try:
                email_results = send_bulk_referral_update_email(users_data)
                flash(f"✅ Successfully updated {rows_updated} active referral coupons! Emails sent: {email_results['success']}, Failed: {email_results['failed']}", "success")
            except Exception as email_error:
                print(f"Email sending failed: {email_error}")
                flash(f"✅ Successfully updated {rows_updated} active referral coupons! (Email notifications failed)", "success")
            
            return redirect(url_for('admin_referral_coupons'))
        
        except Exception as e:
            print(f"Error bulk updating referral coupons: {e}")
            flash(f"❌ Error: {str(e)}", "error")
            return redirect(url_for('admin_referral_coupons'))
        finally:
            conn.close()
    
    @app.route('/admin/referral-coupons/adjust-wallet', methods=['POST'])
    @login_required
    def adjust_user_wallet():
        """Adjust user wallet balance (add or subtract)"""
        if not is_admin():
            return jsonify({'error': 'Access denied'}), 403
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            adjustment_type = data.get('adjustment_type')  # 'add' or 'subtract'
            amount = float(data.get('amount', 0))
            reason = data.get('reason', 'Admin adjustment')
            
            if amount <= 0:
                return jsonify({'error': 'Amount must be positive'}), 400
            
            cur = conn.cursor()
            
            # Get current balance
            cur.execute("SELECT balance FROM wallets WHERE user_id = %s", (user_id,))
            result = cur.fetchone()
            current_balance = float(result[0]) if result else 0
            
            # Calculate new balance
            if adjustment_type == 'add':
                new_balance = current_balance + amount
                transaction_type = 'admin_credit'
                description = f"Admin added ₹{amount}: {reason}"
            else:  # subtract
                new_balance = current_balance - amount
                if new_balance < 0:
                    return jsonify({'error': 'Insufficient balance'}), 400
                transaction_type = 'admin_debit'
                description = f"Admin deducted ₹{amount}: {reason}"
            
            # Update wallet balance
            if result:
                cur.execute("""
                    UPDATE wallets 
                    SET balance = %s, updated_at = CURRENT_TIMESTAMP 
                    WHERE user_id = %s
                """, (new_balance, user_id))
            else:
                cur.execute("""
                    INSERT INTO wallets (user_id, balance, created_at, updated_at)
                    VALUES (%s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, (user_id, new_balance))
            
            # Add transaction record
            cur.execute("""
                INSERT INTO wallet_transactions 
                (user_id, transaction_type, amount, description, balance_after, created_at)
                VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
            """, (user_id, transaction_type, amount, description, new_balance))
            
            conn.commit()
            
            # Get user details for email
            cur.execute("""
                SELECT u.name, u.email, rc.coupon_code
                FROM users u
                LEFT JOIN referral_coupons rc ON u.id = rc.user_id
                WHERE u.id = %s
            """, (user_id,))
            user_data = cur.fetchone()
            
            if user_data:
                # Send email notification
                try:
                    send_referral_update_email(
                        user_email=user_data[1],
                        user_name=user_data[0],
                        referral_code=user_data[2] or 'N/A',
                        wallet_adjustment=True,
                        new_wallet_balance=new_balance,
                        wallet_adjustment_reason=reason
                    )
                except Exception as email_error:
                    print(f"Email sending failed: {email_error}")
            
            return jsonify({
                'success': True,
                'new_balance': new_balance,
                'message': f'Wallet balance updated successfully'
            })
        
        except Exception as e:
            print(f"Error adjusting wallet: {e}")
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()

# Made with Bob
