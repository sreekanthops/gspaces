"""
Wallet and Referral System Module
Handles all wallet-related operations including transactions, bonuses, and referrals
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from decimal import Decimal
from datetime import datetime, timedelta
import json


class WalletSystem:
    """Manages wallet operations for users"""
    
    SIGNUP_BONUS = Decimal("500.00")  # ₹500 signup bonus
    FIRST_ORDER_CASHBACK_PERCENT = Decimal("5.00")  # 5% cashback on first order
    REFERRAL_DISCOUNT_PERCENT = Decimal("5.00")  # 5% discount for referred user
    REFERRAL_BONUS_PERCENT = Decimal("5.00")  # 5% bonus for referrer
    MAX_BONUS_PER_ORDER = Decimal("10000.00")  # Max ₹10,000 bonus usage per order
    REFERRAL_COUPON_VALIDITY_DAYS = 30  # 1 month validity
    
    def __init__(self, conn):
        """Initialize with database connection"""
        self.conn = conn
    
    def get_wallet_balance(self, user_id):
        """Get current wallet balance for a user"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SELECT wallet_balance FROM users WHERE id = %s", (user_id,))
            result = cur.fetchone()
            return Decimal(str(result['wallet_balance'])) if result else Decimal("0.00")
        except Exception as e:
            print(f"Error getting wallet balance: {e}")
            return Decimal("0.00")
    
    def add_transaction(self, user_id, transaction_type, amount, description, 
                       reference_type=None, reference_id=None, metadata=None):
        """
        Add a wallet transaction and update user balance
        
        Args:
            user_id: User ID
            transaction_type: 'credit', 'debit', 'bonus', 'refund', 'referral_bonus'
            amount: Transaction amount (positive for credit, negative for debit)
            description: Transaction description
            reference_type: 'order', 'signup', 'referral', 'first_order', 'admin'
            reference_id: Related order ID or reference
            metadata: Additional JSON data
        """
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Get current balance
            current_balance = self.get_wallet_balance(user_id)
            
            # Calculate new balance
            new_balance = current_balance + Decimal(str(amount))
            if new_balance < 0:
                raise ValueError("Insufficient wallet balance")
            
            # Update user balance
            cur.execute("""
                UPDATE users 
                SET wallet_balance = %s 
                WHERE id = %s
            """, (new_balance, user_id))
            
            # Insert transaction record
            cur.execute("""
                INSERT INTO wallet_transactions 
                (user_id, transaction_type, amount, balance_after, description, 
                 reference_type, reference_id, metadata)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (user_id, transaction_type, amount, new_balance, description,
                  reference_type, reference_id, json.dumps(metadata) if metadata else None))
            
            transaction_id = cur.fetchone()['id']
            self.conn.commit()
            
            return {
                'success': True,
                'transaction_id': transaction_id,
                'new_balance': float(new_balance)
            }
        except Exception as e:
            self.conn.rollback()
            print(f"Error adding transaction: {e}")
            return {'success': False, 'error': str(e)}
    
    def credit_signup_bonus(self, user_id, user_name):
        """Credit signup bonus to new user"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Check if bonus already credited
            cur.execute("""
                SELECT signup_bonus_credited FROM users WHERE id = %s
            """, (user_id,))
            result = cur.fetchone()
            
            if result and result['signup_bonus_credited']:
                return {'success': False, 'error': 'Signup bonus already credited'}
            
            # Credit bonus
            result = self.add_transaction(
                user_id=user_id,
                transaction_type='bonus',
                amount=self.SIGNUP_BONUS,
                description=f'Welcome bonus for {user_name}',
                reference_type='signup',
                metadata={'bonus_type': 'signup'}
            )
            
            if result['success']:
                # Mark bonus as credited
                cur.execute("""
                    UPDATE users 
                    SET signup_bonus_credited = TRUE 
                    WHERE id = %s
                """, (user_id,))
                self.conn.commit()
            
            return result
        except Exception as e:
            self.conn.rollback()
            print(f"Error crediting signup bonus: {e}")
            return {'success': False, 'error': str(e)}
    
    def credit_first_order_cashback(self, user_id, order_id, order_amount):
        """Credit 5% cashback on first order"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Check if this is first order and cashback not yet credited
            cur.execute("""
                SELECT first_order_completed FROM users WHERE id = %s
            """, (user_id,))
            result = cur.fetchone()
            
            if result and result['first_order_completed']:
                return {'success': False, 'error': 'First order cashback already credited'}
            
            # Calculate cashback (5% of order amount)
            cashback_amount = (Decimal(str(order_amount)) * self.FIRST_ORDER_CASHBACK_PERCENT / 100).quantize(Decimal('0.01'))
            
            # Credit cashback
            result = self.add_transaction(
                user_id=user_id,
                transaction_type='bonus',
                amount=cashback_amount,
                description=f'First order cashback (5% of ₹{order_amount})',
                reference_type='first_order',
                reference_id=order_id,
                metadata={'cashback_percent': float(self.FIRST_ORDER_CASHBACK_PERCENT)}
            )
            
            if result['success']:
                # Mark first order as completed and update order
                cur.execute("""
                    UPDATE users 
                    SET first_order_completed = TRUE 
                    WHERE id = %s
                """, (user_id,))
                
                cur.execute("""
                    UPDATE orders 
                    SET cashback_earned = %s, cashback_credited = TRUE 
                    WHERE id = %s
                """, (cashback_amount, order_id))
                
                self.conn.commit()
            
            return result
        except Exception as e:
            self.conn.rollback()
            print(f"Error crediting first order cashback: {e}")
            return {'success': False, 'error': str(e)}
    
    def process_referral_bonus(self, referrer_user_id, referred_user_id, order_id, order_amount):
        """
        Process referral bonus when referred user makes first order
        Both referrer and referred user get 5% bonus
        """
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Check if referred user has already received referral bonus
            cur.execute("""
                SELECT COUNT(*) as count FROM wallet_transactions 
                WHERE user_id = %s AND reference_type = 'referral' AND transaction_type = 'bonus'
            """, (referred_user_id,))
            
            if cur.fetchone()['count'] > 0:
                return {'success': False, 'error': 'Referral bonus already processed'}
            
            # Calculate bonus (5% of order amount)
            bonus_amount = (Decimal(str(order_amount)) * self.REFERRAL_BONUS_PERCENT / 100).quantize(Decimal('0.01'))
            
            # Credit bonus to referrer
            referrer_result = self.add_transaction(
                user_id=referrer_user_id,
                transaction_type='referral_bonus',
                amount=bonus_amount,
                description=f'Referral bonus from order #{order_id}',
                reference_type='referral',
                reference_id=order_id,
                metadata={'referred_user_id': referred_user_id, 'bonus_percent': float(self.REFERRAL_BONUS_PERCENT)}
            )
            
            # Credit bonus to referred user
            referred_result = self.add_transaction(
                user_id=referred_user_id,
                transaction_type='bonus',
                amount=bonus_amount,
                description=f'Referral bonus on your first order',
                reference_type='referral',
                reference_id=order_id,
                metadata={'referrer_user_id': referrer_user_id, 'bonus_percent': float(self.REFERRAL_BONUS_PERCENT)}
            )
            
            # Update referral coupon stats
            cur.execute("""
                UPDATE referral_coupons 
                SET total_referral_earnings = total_referral_earnings + %s
                WHERE user_id = %s
            """, (bonus_amount, referrer_user_id))
            
            self.conn.commit()
            
            return {
                'success': True,
                'referrer_bonus': float(bonus_amount),
                'referred_bonus': float(bonus_amount)
            }
        except Exception as e:
            self.conn.rollback()
            print(f"Error processing referral bonus: {e}")
            return {'success': False, 'error': str(e)}
    
    def deduct_from_wallet(self, user_id, amount, order_id, description="Payment from wallet"):
        """Deduct amount from wallet for order payment"""
        try:
            # Ensure amount is positive
            amount = abs(Decimal(str(amount)))
            
            # Check if user has sufficient balance
            current_balance = self.get_wallet_balance(user_id)
            if current_balance < amount:
                return {'success': False, 'error': 'Insufficient wallet balance'}
            
            # Deduct amount (negative transaction)
            result = self.add_transaction(
                user_id=user_id,
                transaction_type='debit',
                amount=-amount,  # Negative for debit
                description=description,
                reference_type='order',
                reference_id=order_id
            )
            
            return result
        except Exception as e:
            print(f"Error deducting from wallet: {e}")
            return {'success': False, 'error': str(e)}
    
    def calculate_wallet_usage(self, user_id, order_total):
        """
        Calculate how much wallet balance can be used for an order
        Respects the bonus limit of ₹10,000 per order
        """
        try:
            wallet_balance = self.get_wallet_balance(user_id)
            
            # Maximum that can be used is the lesser of:
            # 1. Wallet balance
            # 2. Order total
            # 3. Bonus limit (₹10,000)
            max_usable = min(wallet_balance, Decimal(str(order_total)), self.MAX_BONUS_PER_ORDER)
            
            return {
                'wallet_balance': float(wallet_balance),
                'max_usable': float(max_usable),
                'remaining_to_pay': float(Decimal(str(order_total)) - max_usable)
            }
        except Exception as e:
            print(f"Error calculating wallet usage: {e}")
            return {
                'wallet_balance': 0.00,
                'max_usable': 0.00,
                'remaining_to_pay': float(order_total)
            }
    
    def get_transaction_history(self, user_id, limit=50):
        """Get wallet transaction history for a user"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT 
                    id, transaction_type, amount, balance_after, 
                    description, reference_type, reference_id, 
                    created_at, metadata
                FROM wallet_transactions
                WHERE user_id = %s
                ORDER BY created_at DESC
                LIMIT %s
            """, (user_id, limit))
            
            transactions = cur.fetchall()
            
            # Convert to list of dicts with proper formatting
            result = []
            for txn in transactions:
                result.append({
                    'id': txn['id'],
                    'type': txn['transaction_type'],
                    'amount': float(txn['amount']),
                    'balance_after': float(txn['balance_after']),
                    'description': txn['description'],
                    'reference_type': txn['reference_type'],
                    'reference_id': txn['reference_id'],
                    'date': txn['created_at'].strftime('%Y-%m-%d %H:%M:%S'),
                    'metadata': json.loads(txn['metadata']) if txn['metadata'] else {}
                })
            
            return result
        except Exception as e:
            print(f"Error getting transaction history: {e}")
            return []
    
    def get_referral_stats(self, user_id):
        """Get referral statistics for a user"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Get referral coupon info
            cur.execute("""
                SELECT 
                    coupon_code, times_used, total_referral_earnings, 
                    is_active, expires_at
                FROM referral_coupons
                WHERE user_id = %s
            """, (user_id,))
            
            coupon_info = cur.fetchone()
            
            if not coupon_info:
                return None
            
            # Get list of users who used this referral code
            cur.execute("""
                SELECT 
                    u.name, u.email, cu.used_at, cu.discount_amount, cu.referrer_bonus_amount
                FROM coupon_usage cu
                JOIN users u ON cu.user_id = u.id
                WHERE cu.coupon_code = %s
                ORDER BY cu.used_at DESC
            """, (coupon_info['coupon_code'],))
            
            referrals = cur.fetchall()
            
            return {
                'coupon_code': coupon_info['coupon_code'],
                'times_used': coupon_info['times_used'],
                'total_earnings': float(coupon_info['total_referral_earnings']),
                'is_active': coupon_info['is_active'],
                'expires_at': coupon_info['expires_at'].strftime('%Y-%m-%d') if coupon_info['expires_at'] else None,
                'referrals': [
                    {
                        'name': r['name'],
                        'email': r['email'],
                        'used_at': r['used_at'].strftime('%Y-%m-%d'),
                        'discount_given': float(r['discount_amount']),
                        'bonus_earned': float(r['referrer_bonus_amount'])
                    }
                    for r in referrals
                ]
            }
        except Exception as e:
            print(f"Error getting referral stats: {e}")
            return None
    
    def validate_referral_coupon(self, coupon_code, user_id):
        """Validate if a referral coupon can be used by a user"""
        try:
            cur = self.conn.cursor(cursor_factory=RealDictCursor)
            
            # Get coupon info
            cur.execute("""
                SELECT rc.*, u.name as referrer_name
                FROM referral_coupons rc
                JOIN users u ON rc.user_id = u.id
                WHERE rc.coupon_code = %s
            """, (coupon_code.upper(),))
            
            coupon = cur.fetchone()
            
            if not coupon:
                return {'valid': False, 'error': 'Invalid referral code'}
            
            if not coupon['is_active']:
                return {'valid': False, 'error': 'This referral code is no longer active'}
            
            if coupon['expires_at'] and datetime.now() > coupon['expires_at']:
                return {'valid': False, 'error': 'This referral code has expired'}
            
            # Check if user is trying to use their own referral code
            if coupon['user_id'] == user_id:
                return {'valid': False, 'error': 'You cannot use your own referral code'}
            
            # Check if user has already used this coupon
            cur.execute("""
                SELECT COUNT(*) as count FROM coupon_usage
                WHERE user_id = %s AND coupon_code = %s
            """, (user_id, coupon_code.upper()))
            
            if cur.fetchone()['count'] > 0:
                return {'valid': False, 'error': 'You have already used this referral code'}
            
            return {
                'valid': True,
                'coupon_code': coupon['coupon_code'],
                'discount_percentage': float(coupon['discount_percentage']),
                'referrer_name': coupon['referrer_name'],
                'referrer_id': coupon['user_id']
            }
        except Exception as e:
            print(f"Error validating referral coupon: {e}")
            return {'valid': False, 'error': 'Error validating coupon'}

# Made with Bob
