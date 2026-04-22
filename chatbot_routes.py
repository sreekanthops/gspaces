"""
Chatbot Routes for GSpaces
Provides intelligent conversation, product search, wallet info, coupons, contact, and order tracking
"""

from flask import Blueprint, request, jsonify, session
from flask_login import current_user, login_required
from psycopg2.extras import RealDictCursor
import re
from decimal import Decimal

def add_chatbot_routes(app, connect_to_db):
    """Add chatbot routes to the Flask app"""
    
    @app.route('/chatbot/message', methods=['POST'])
    def chatbot_message():
        """Handle chatbot messages with NLU"""
        try:
            data = request.get_json()
            message = data.get('message', '').lower().strip()
            
            if not message:
                return jsonify({'error': 'Message is required'}), 400
            
            # NLU - Detect intent
            response = process_message(message)
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Chatbot error: {e}")
            return jsonify({'error': 'Something went wrong'}), 500
    
    @app.route('/chatbot/products_by_budget', methods=['POST'])
    def chatbot_products_by_budget():
        """Search products by budget range"""
        try:
            data = request.get_json()
            budget = float(data.get('budget', 0))
            
            if budget <= 0:
                return jsonify({'error': 'Invalid budget'}), 400
            
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Find products within budget (with 10% margin)
            max_price = budget * 1.1
            cursor.execute("""
                SELECT id, name, price, image_url, description
                FROM products
                WHERE price <= %s AND stock > 0
                ORDER BY price ASC
                LIMIT 10
            """, (max_price,))
            
            products = cursor.fetchall()
            conn.close()
            
            # Convert Decimal to float for JSON
            for product in products:
                product['price'] = float(product['price'])
            
            return jsonify({
                'products': products,
                'count': len(products)
            })
            
        except Exception as e:
            print(f"Budget search error: {e}")
            return jsonify({'error': 'Failed to search products'}), 500
    
    @app.route('/chatbot/wallet_info', methods=['GET'])
    @login_required
    def chatbot_wallet_info():
        """Get user's wallet balance"""
        try:
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            cursor.execute("""
                SELECT balance, total_earned, total_spent
                FROM wallets
                WHERE user_id = %s
            """, (current_user.id,))
            
            wallet = cursor.fetchone()
            conn.close()
            
            if wallet:
                return jsonify({
                    'balance': float(wallet['balance']),
                    'total_earned': float(wallet['total_earned']),
                    'total_spent': float(wallet['total_spent'])
                })
            else:
                return jsonify({
                    'balance': 0.0,
                    'total_earned': 0.0,
                    'total_spent': 0.0
                })
                
        except Exception as e:
            print(f"Wallet info error: {e}")
            return jsonify({'error': 'Failed to fetch wallet info'}), 500
    
    @app.route('/chatbot/coupons', methods=['GET'])
    @login_required
    def chatbot_coupons():
        """Get all available coupons for user"""
        try:
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get personal coupons
            cursor.execute("""
                SELECT code, discount_percent, min_order_value, max_discount, 
                       valid_from, valid_until, usage_limit, times_used
                FROM coupons
                WHERE user_id = %s 
                AND valid_until >= CURRENT_DATE
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_percent DESC
            """, (current_user.id,))
            personal_coupons = cursor.fetchall()
            
            # Get referral coupons
            cursor.execute("""
                SELECT code, discount_percent, min_order_value, max_discount,
                       valid_from, valid_until, usage_limit, times_used
                FROM referral_coupons
                WHERE user_id = %s
                AND valid_until >= CURRENT_DATE
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_percent DESC
            """, (current_user.id,))
            referral_coupons = cursor.fetchall()
            
            # Get bonus/public coupons
            cursor.execute("""
                SELECT code, discount_percent, min_order_value, max_discount,
                       valid_from, valid_until, usage_limit, times_used
                FROM coupons
                WHERE user_id IS NULL
                AND valid_until >= CURRENT_DATE
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_percent DESC
            """)
            bonus_coupons = cursor.fetchall()
            
            conn.close()
            
            # Convert dates and decimals to strings/floats
            def format_coupon(c):
                return {
                    'code': c['code'],
                    'discount_percent': float(c['discount_percent']),
                    'min_order_value': float(c['min_order_value']) if c['min_order_value'] else 0,
                    'max_discount': float(c['max_discount']) if c['max_discount'] else None,
                    'valid_from': str(c['valid_from']),
                    'valid_until': str(c['valid_until']),
                    'usage_limit': c['usage_limit'],
                    'times_used': c['times_used']
                }
            
            return jsonify({
                'personal': [format_coupon(c) for c in personal_coupons],
                'referral': [format_coupon(c) for c in referral_coupons],
                'bonus': [format_coupon(c) for c in bonus_coupons]
            })
            
        except Exception as e:
            print(f"Coupons fetch error: {e}")
            return jsonify({'error': 'Failed to fetch coupons'}), 500
    
    @app.route('/chatbot/contact_info', methods=['GET'])
    def chatbot_contact_info():
        """Get contact information"""
        return jsonify({
            'phone': '+91 9390933399',
            'email': 'support@gspaces.in',
            'address': 'Hyderabad, Telangana, India',
            'support_hours': 'Monday - Saturday: 9:00 AM - 6:00 PM IST',
            'whatsapp': '+91 9390933399'
        })
    
    @app.route('/chatbot/orders', methods=['GET'])
    @login_required
    def chatbot_orders():
        """Get user's recent orders"""
        try:
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            cursor.execute("""
                SELECT id, order_id, total_amount, status, created_at
                FROM orders
                WHERE user_id = %s
                ORDER BY created_at DESC
                LIMIT 5
            """, (current_user.id,))
            
            orders = cursor.fetchall()
            conn.close()
            
            # Format orders
            formatted_orders = []
            for order in orders:
                formatted_orders.append({
                    'id': order['id'],
                    'order_id': order['order_id'],
                    'total_amount': float(order['total_amount']),
                    'status': order['status'],
                    'created_at': str(order['created_at'])
                })
            
            return jsonify({'orders': formatted_orders})
            
        except Exception as e:
            print(f"Orders fetch error: {e}")
            return jsonify({'error': 'Failed to fetch orders'}), 500
    
    @app.route('/chatbot/track_order', methods=['POST'])
    @login_required
    def chatbot_track_order():
        """Track specific order by order ID"""
        try:
            data = request.get_json()
            order_id = data.get('order_id', '').strip()
            
            if not order_id:
                return jsonify({'error': 'Order ID is required'}), 400
            
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            cursor.execute("""
                SELECT id, order_id, total_amount, status, created_at, 
                       shipping_address, payment_method
                FROM orders
                WHERE order_id = %s AND user_id = %s
            """, (order_id, current_user.id))
            
            order = cursor.fetchone()
            conn.close()
            
            if not order:
                return jsonify({'error': 'Order not found'}), 404
            
            return jsonify({
                'order_id': order['order_id'],
                'total_amount': float(order['total_amount']),
                'status': order['status'],
                'created_at': str(order['created_at']),
                'shipping_address': order['shipping_address'],
                'payment_method': order['payment_method']
            })
            
        except Exception as e:
            print(f"Track order error: {e}")
            return jsonify({'error': 'Failed to track order'}), 500
    
    def process_message(message):
        """Process user message and return appropriate response using NLU"""
        
        # Greeting patterns
        if re.search(r'\b(hi|hello|hey|greetings)\b', message):
            return {
                'type': 'text',
                'message': 'Hello! 👋 I\'m your GSpaces assistant. I can help you with:\n\n' +
                          '💰 Finding products within your budget\n' +
                          '🎫 Checking available coupons\n' +
                          '💳 Viewing your wallet balance\n' +
                          '📦 Tracking your orders\n' +
                          '📞 Getting contact information\n\n' +
                          'How can I assist you today?'
            }
        
        # Budget/price search
        budget_match = re.search(r'(\d+)\s*(rupees?|rs\.?|inr|₹)?', message)
        if budget_match and any(word in message for word in ['budget', 'price', 'under', 'within', 'afford', 'cost']):
            budget = float(budget_match.group(1))
            return {
                'type': 'budget_search',
                'budget': budget,
                'message': f'Let me find products within ₹{budget} for you...'
            }
        
        # Wallet inquiry
        if any(word in message for word in ['wallet', 'balance', 'money', 'credit']):
            if current_user.is_authenticated:
                return {
                    'type': 'wallet',
                    'message': 'Fetching your wallet information...'
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your wallet balance.'
                }
        
        # Coupon inquiry
        if any(word in message for word in ['coupon', 'discount', 'offer', 'promo', 'code']):
            if current_user.is_authenticated:
                return {
                    'type': 'coupons',
                    'message': 'Here are your available coupons...'
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your coupons.'
                }
        
        # Contact inquiry
        if any(word in message for word in ['contact', 'phone', 'email', 'address', 'reach', 'support', 'help']):
            return {
                'type': 'contact',
                'message': 'Here\'s how you can reach us...'
            }
        
        # Order tracking
        if any(word in message for word in ['order', 'track', 'delivery', 'shipping', 'status']):
            if current_user.is_authenticated:
                return {
                    'type': 'orders',
                    'message': 'Let me fetch your recent orders...'
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your orders.'
                }
        
        # Product inquiry
        if any(word in message for word in ['product', 'desk', 'chair', 'setup', 'furniture', 'office']):
            return {
                'type': 'text',
                'message': 'We offer a wide range of office furniture and setups! You can:\n\n' +
                          '• Browse our products section\n' +
                          '• Tell me your budget to find suitable options\n' +
                          '• Check available discounts and offers\n\n' +
                          'What would you like to know more about?'
            }
        
        # Default response
        return {
            'type': 'text',
            'message': 'I\'m here to help! You can ask me about:\n\n' +
                      '💰 Products within your budget\n' +
                      '🎫 Available coupons and discounts\n' +
                      '💳 Your wallet balance\n' +
                      '📦 Order tracking\n' +
                      '📞 Contact information\n\n' +
                      'What would you like to know?'
        }

# Made with Bob
