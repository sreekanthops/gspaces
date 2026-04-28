"""
Wallet System Routes
Add these routes to main.py or import this module
"""

from flask import jsonify, request, render_template
from flask_login import login_required, current_user
from decimal import Decimal
from wallet_system import WalletSystem
from datetime import datetime, timedelta


def add_wallet_routes(app, connect_to_db):
    """Add wallet-related routes to the Flask app"""
    
    @app.route('/api/wallet/balance')
    @login_required
    def get_wallet_balance():
        """Get current wallet balance"""
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            wallet = WalletSystem(conn)
            balance = wallet.get_wallet_balance(current_user.id)
            usage_info = wallet.calculate_wallet_usage(current_user.id, 100000)  # Max possible
            
            return jsonify({
                'success': True,
                'balance': float(balance),
                'max_bonus_per_order': float(WalletSystem.MAX_BONUS_PER_ORDER)
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()
    
    @app.route('/api/wallet/transactions')
    @login_required
    def get_wallet_transactions():
        """Get wallet transaction history"""
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            limit = request.args.get('limit', 50, type=int)
            wallet = WalletSystem(conn)
            transactions = wallet.get_transaction_history(current_user.id, limit)
            
            return jsonify({
                'success': True,
                'transactions': transactions
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()
    
    @app.route('/api/wallet/calculate-usage', methods=['POST'])
    @login_required
    def calculate_wallet_usage():
        """Calculate how much wallet balance can be used for an order"""
        data = request.get_json()
        order_total = Decimal(str(data.get('order_total', 0)))
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            wallet = WalletSystem(conn)
            usage_info = wallet.calculate_wallet_usage(current_user.id, order_total)
            
            return jsonify({
                'success': True,
                **usage_info
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()
    
    @app.route('/api/referral/info')
    @login_required
    def get_referral_info():
        """Get user's referral code and statistics"""
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            wallet = WalletSystem(conn)
            stats = wallet.get_referral_stats(current_user.id)
            
            if not stats:
                # Create referral coupon if doesn't exist
                from psycopg2.extras import RealDictCursor
                cur = conn.cursor(cursor_factory=RealDictCursor)
                
                # Get user's referral code
                cur.execute("SELECT referral_code FROM users WHERE id = %s", (current_user.id,))
                user_data = cur.fetchone()
                
                if user_data and user_data['referral_code']:
                    # Create referral coupon
                    cur.execute("""
                        INSERT INTO referral_coupons (user_id, coupon_code, expires_at)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (user_id) DO NOTHING
                    """, (current_user.id, user_data['referral_code'], 
                          datetime.now() + timedelta(days=30)))
                    conn.commit()
                    
                    stats = wallet.get_referral_stats(current_user.id)
            
            return jsonify({
                'success': True,
                'referral_info': stats
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        finally:
            conn.close()
    
    @app.route('/api/referral/validate', methods=['POST'])
    @login_required
    def validate_referral_code():
        """Validate a referral code"""
        data = request.get_json()
        coupon_code = data.get('code', '').strip().upper()
        
        if not coupon_code:
            return jsonify({'valid': False, 'error': 'Please enter a referral code'})
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            wallet = WalletSystem(conn)
            result = wallet.validate_referral_coupon(coupon_code, current_user.id)
            
            return jsonify(result)
        except Exception as e:
            return jsonify({'valid': False, 'error': str(e)})
        finally:
            conn.close()
    
    @app.route('/wallet')
    @login_required
    def wallet():
        """Wallet page showing balance and transactions"""
        conn = connect_to_db()
        if not conn:
            return "Database connection failed", 500
        
        try:
            wallet = WalletSystem(conn)
            balance = wallet.get_wallet_balance(current_user.id)
            transactions = wallet.get_transaction_history(current_user.id, 50)
            referral_stats = wallet.get_referral_stats(current_user.id)
            
            # Referral benefits info for display
            referral_benefits = {
                'friend_discount': '5% off',
                'owner_bonus': '5% bonus'
            }
            
            return render_template('wallet.html',
                                 balance=float(balance),
                                 transactions=transactions,
                                 referral_stats=referral_stats,
                                 referral_benefits=referral_benefits,
                                 max_bonus_per_order=float(WalletSystem.MAX_BONUS_PER_ORDER))
        except Exception as e:
            return f"Error loading wallet: {e}", 500
        finally:
            conn.close()
    
    @app.route('/wallet/redeem_coupon', methods=['POST'])
    @login_required
    def redeem_wallet_coupon():
        """Redeem a wallet coupon code to add balance"""
        from flask import flash, redirect, url_for
        from psycopg2.extras import RealDictCursor
        
        # Check if this is an AJAX request
        is_ajax = request.headers.get('X-Requested-With') == 'XMLHttpRequest'
        
        coupon_code = request.form.get('coupon_code', '').strip().upper()
        
        if not coupon_code:
            if is_ajax:
                return jsonify({'success': False, 'message': 'Please enter a coupon code'})
            flash('Please enter a coupon code', 'error')
            return redirect(url_for('wallet'))
        
        conn = connect_to_db()
        if not conn:
            if is_ajax:
                return jsonify({'success': False, 'message': 'Database connection failed. Please try again.'})
            flash('Database connection failed. Please try again.', 'error')
            return redirect(url_for('wallet'))
        
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # 1. Check if coupon exists and is valid
            cur.execute("""
                SELECT
                    id, code, discount_type, discount_value, coupon_type, expiry_type,
                    valid_until, is_active, user_id
                FROM coupons
                WHERE UPPER(code) = %s
            """, (coupon_code,))
            
            coupon = cur.fetchone()
            
            if not coupon:
                if is_ajax:
                    return jsonify({'success': False, 'message': 'Invalid coupon code'})
                flash('Invalid coupon code', 'error')
                return redirect(url_for('wallet'))
            
            # 2. Check if coupon is active
            if not coupon['is_active']:
                if is_ajax:
                    return jsonify({'success': False, 'message': 'This coupon is no longer active'})
                flash('This coupon is no longer active', 'error')
                return redirect(url_for('wallet'))
            
            # 3. Check coupon type (must be 'wallet' or 'both')
            if coupon['coupon_type'] not in ['wallet', 'both']:
                if is_ajax:
                    return jsonify({'success': False, 'message': 'This coupon cannot be used for wallet redemption'})
                flash('This coupon cannot be used for wallet redemption', 'error')
                return redirect(url_for('wallet'))
            
            # 4. Check if coupon is private (user_id bound)
            if coupon['user_id'] is not None and coupon['user_id'] != current_user.id:
                if is_ajax:
                    return jsonify({'success': False, 'message': 'This is a private coupon and can only be used by the assigned user'})
                flash('This is a private coupon and can only be used by the assigned user', 'error')
                return redirect(url_for('wallet'))
            
            # 5. Check expiry (only if expiry_type is 'expiry')
            if coupon['expiry_type'] == 'expiry' and coupon['valid_until']:
                # Convert both to date objects for comparison
                valid_until_date = coupon['valid_until'].date() if hasattr(coupon['valid_until'], 'date') else coupon['valid_until']
                if datetime.now().date() > valid_until_date:
                    if is_ajax:
                        return jsonify({'success': False, 'message': 'This coupon has expired'})
                    flash('This coupon has expired', 'error')
                    return redirect(url_for('wallet'))
            
            # 6. Check if user has already used this coupon
            cur.execute("""
                SELECT id FROM coupon_usage
                WHERE coupon_code = %s AND user_id = %s
            """, (coupon_code, current_user.id))
            
            if cur.fetchone():
                if is_ajax:
                    return jsonify({'success': False, 'message': 'You have already used this coupon'})
                flash('You have already used this coupon', 'error')
                return redirect(url_for('wallet'))
            
            # 7. Special verification for GSPACES_DESKS_FOLLOW coupon
            instagram_warning = None
            if coupon_code == 'GSPACES_DESKS_FOLLOW':
                # Show reminder to follow on Instagram with clickable link and icon
                instagram_warning = 'Please make sure you are following <a href="https://www.instagram.com/gspaces_desks/" target="_blank" style="color: #E1306C; font-weight: 600; text-decoration: none; display: inline-flex; align-items: center; gap: 4px;"><i class="bi bi-instagram" style="font-size: 1.2rem;"></i> @gspaces_desks</a> on Instagram to use this coupon'
                if not is_ajax:
                    flash(instagram_warning, 'warning')
            
            # 8. Add amount to wallet
            wallet = WalletSystem(conn)
            amount = Decimal(str(coupon['discount_value']))
            
            result = wallet.add_transaction(
                user_id=current_user.id,
                transaction_type='bonus',
                amount=amount,
                description=f"Coupon redeemed: {coupon_code}",
                reference_type='coupon',
                reference_id=coupon['id'],
                metadata={'coupon_code': coupon_code, 'coupon_type': 'wallet'}
            )
            
            if not result['success']:
                flash(f"Failed to add balance: {result.get('error', 'Unknown error')}", 'error')
                return redirect(url_for('wallet'))
            
            # 9. Record coupon usage
            cur.execute("""
                INSERT INTO coupon_usage
                (coupon_id, coupon_code, user_id, discount_amount, discount_applied, used_at, usage_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (coupon['id'], coupon_code, current_user.id, amount, amount, datetime.now(), 'wallet'))
            
            conn.commit()
            
            # Get updated balance
            wallet = WalletSystem(conn)
            new_balance = wallet.get_wallet_balance(current_user.id)
            
            # Return JSON for AJAX or redirect for regular form
            if is_ajax:
                response_data = {
                    'success': True,
                    'message': f'🎉 Congratulations! You earned ₹{amount} from coupon "{coupon_code}"! Your wallet has been credited. 🌟',
                    'amount': float(amount),
                    'new_balance': float(new_balance),
                    'coupon_code': coupon_code
                }
                if instagram_warning:
                    response_data['warning'] = instagram_warning
                return jsonify(response_data)
            else:
                flash(f'🎉 Congratulations! You earned ₹{amount} from coupon "{coupon_code}"! Your wallet has been credited. 🌟', 'coupon_success')
                return redirect(url_for('wallet'))
            
        except Exception as e:
            conn.rollback()
            print(f"Error redeeming coupon: {e}")
            error_msg = 'An error occurred while redeeming the coupon. Please try again.'
            if is_ajax:
                return jsonify({'success': False, 'message': error_msg})
            flash(error_msg, 'error')
            return redirect(url_for('wallet'))
        finally:
            conn.close()


def integrate_wallet_with_signup(cursor, conn, user_id, user_name):
    """
    Call this function after user signup to:
    1. Credit signup bonus
    2. Create referral coupon automatically
    """
    try:
        from psycopg2.extras import RealDictCursor
        
        # Credit signup bonus
        wallet = WalletSystem(conn)
        result = wallet.credit_signup_bonus(user_id, user_name)
        
        if result['success']:
            print(f"Signup bonus credited to user {user_id}: ₹{WalletSystem.SIGNUP_BONUS}")
        else:
            print(f"Failed to credit signup bonus: {result.get('error')}")
        
        # Get user's referral code
        cursor.execute("SELECT referral_code FROM users WHERE id = %s", (user_id,))
        user_data = cursor.fetchone()
        
        # Create referral coupon if user has a referral code
        if user_data and user_data.get('referral_code'):
            referral_code = user_data['referral_code']
            
            # Check if referral coupon already exists
            cursor.execute("""
                SELECT id FROM referral_coupons WHERE user_id = %s
            """, (user_id,))
            
            if not cursor.fetchone():
                # Create referral coupon
                cursor.execute("""
                    INSERT INTO referral_coupons (
                        user_id, coupon_code, discount_percentage,
                        referral_bonus_percentage, times_used,
                        total_referral_earnings, is_active,
                        created_at, expires_at
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    user_id,
                    referral_code,
                    WalletSystem.REFERRAL_DISCOUNT_PERCENT,
                    WalletSystem.REFERRAL_BONUS_PERCENT,
                    0,  # times_used
                    0.00,  # total_referral_earnings
                    True,  # is_active
                    datetime.now(),
                    datetime.now() + timedelta(days=365)  # 1 year validity
                ))
                conn.commit()
                print(f"Referral coupon created for user {user_id}: {referral_code}")
            else:
                print(f"Referral coupon already exists for user {user_id}")
        
        return result
    except Exception as e:
        print(f"Error in integrate_wallet_with_signup: {e}")
        return {'success': False, 'error': str(e)}


def integrate_wallet_with_order(conn, user_id, order_id, order_amount, 
                                wallet_amount_used=0, referral_code_used=None):
    """
    Call this function after order is confirmed to:
    1. Deduct wallet amount if used
    2. Credit first order cashback (5%)
    3. Process referral bonus if referral code was used
    
    Add this to the payment_success route after order creation
    """
    try:
        from psycopg2.extras import RealDictCursor
        wallet = WalletSystem(conn)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. Deduct wallet amount if used
        if wallet_amount_used > 0:
            deduct_result = wallet.deduct_from_wallet(
                user_id, 
                wallet_amount_used, 
                order_id,
                f"Payment for order #{order_id}"
            )
            if not deduct_result['success']:
                print(f"Failed to deduct wallet amount: {deduct_result.get('error')}")
        
        # 2. Check if this is first order and credit cashback
        cur.execute("""
            SELECT first_order_completed FROM users WHERE id = %s
        """, (user_id,))
        user_data = cur.fetchone()
        
        if user_data and not user_data['first_order_completed']:
            cashback_result = wallet.credit_first_order_cashback(user_id, order_id, order_amount)
            if cashback_result['success']:
                print(f"First order cashback credited: ₹{cashback_result.get('new_balance')}")
        
        # 3. Process referral bonus if referral code was used
        if referral_code_used:
            # Get referrer user ID
            cur.execute("""
                SELECT user_id FROM referral_coupons WHERE coupon_code = %s
            """, (referral_code_used.upper(),))
            referrer_data = cur.fetchone()
            
            if referrer_data:
                referrer_id = referrer_data['user_id']
                
                # Check if this is the referred user's first order
                if user_data and not user_data['first_order_completed']:
                    bonus_result = wallet.process_referral_bonus(
                        referrer_id, user_id, order_id, order_amount
                    )
                    if bonus_result['success']:
                        print(f"Referral bonus processed: ₹{bonus_result.get('referrer_bonus')} each")
                        
                        # Update coupon usage
                        discount_amount = (Decimal(str(order_amount)) * 
                                         WalletSystem.REFERRAL_DISCOUNT_PERCENT / 100).quantize(Decimal('0.01'))
                        
                        cur.execute("""
                            INSERT INTO coupon_usage 
                            (coupon_code, user_id, order_id, discount_amount, referrer_bonus_amount)
                            VALUES (%s, %s, %s, %s, %s)
                        """, (referral_code_used.upper(), user_id, order_id, 
                              discount_amount, bonus_result.get('referrer_bonus', 0)))
                        
                        # Update referral coupon stats
                        cur.execute("""
                            UPDATE referral_coupons 
                            SET times_used = times_used + 1
                            WHERE coupon_code = %s
                        """, (referral_code_used.upper(),))
                        
                        conn.commit()
        
        return {'success': True}
    except Exception as e:
        print(f"Error in integrate_wallet_with_order: {e}")
        conn.rollback()
        return {'success': False, 'error': str(e)}

# Made with Bob
