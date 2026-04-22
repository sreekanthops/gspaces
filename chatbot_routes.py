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
            min_budget = float(data.get('min_budget', 0))
            max_budget = float(data.get('max_budget', 0))
            
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Handle range search
            if min_budget > 0 and max_budget > 0:
                cursor.execute("""
                    SELECT id, name, price, image_url, description
                    FROM products
                    WHERE price BETWEEN %s AND %s
                    ORDER BY price ASC
                    LIMIT 10
                """, (min_budget, max_budget))
            # Handle single budget with 10% margin
            elif budget > 0:
                max_price = budget * 1.1
                cursor.execute("""
                    SELECT id, name, price, image_url, description
                    FROM products
                    WHERE price <= %s
                    ORDER BY price ASC
                    LIMIT 10
                """, (max_price,))
            else:
                return jsonify({'error': 'Invalid budget'}), 400
            
            products = cursor.fetchall()
            conn.close()
            
            # Convert Decimal to float and fix image URLs
            for product in products:
                product['price'] = float(product['price'])
                # Fix image URL to include /static/ prefix if needed
                if product['image_url']:
                    # If it starts with img/, replace with /static/img/
                    if product['image_url'].startswith('img/'):
                        product['image_url'] = '/static/' + product['image_url']
                    # If it starts with /img/, replace with /static/img/
                    elif product['image_url'].startswith('/img/'):
                        product['image_url'] = product['image_url'].replace('/img/', '/static/img/')
                    # If it doesn't start with /static/ or http, add /static/img/Products/
                    elif not product['image_url'].startswith('/static/') and not product['image_url'].startswith('http'):
                        product['image_url'] = '/static/img/Products/' + product['image_url']
            
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
            
            # Get wallet balance
            cursor.execute("""
                SELECT balance
                FROM wallets
                WHERE user_id = %s
            """, (current_user.id,))
            
            wallet = cursor.fetchone()
            
            # Calculate total earned and spent from transactions
            cursor.execute("""
                SELECT
                    COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as total_earned,
                    COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) as total_spent
                FROM wallet_transactions
                WHERE user_id = %s
            """, (current_user.id,))
            
            transactions = cursor.fetchone()
            conn.close()
            
            if wallet:
                return jsonify({
                    'balance': float(wallet['balance']),
                    'total_earned': float(transactions['total_earned']) if transactions else 0.0,
                    'total_spent': float(transactions['total_spent']) if transactions else 0.0
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
                SELECT code, discount_value as discount_percent, min_order_amount as min_order_value,
                       max_discount_amount as max_discount, created_at as valid_from,
                       COALESCE(valid_until, created_at + INTERVAL '30 days') as valid_until,
                       usage_limit, times_used
                FROM coupons
                WHERE user_id = %s
                AND is_active = true
                AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_value DESC
            """, (current_user.id,))
            personal_coupons = cursor.fetchall()
            
            # Get referral coupons (uses coupon_code instead of code)
            cursor.execute("""
                SELECT coupon_code as code,
                       COALESCE(discount_amount, discount_percentage) as discount_percent,
                       COALESCE(min_order_amount, 0) as min_order_value,
                       max_discount_amount as max_discount,
                       created_at as valid_from,
                       expires_at as valid_until,
                       usage_limit,
                       times_used
                FROM referral_coupons
                WHERE user_id = %s
                AND (expires_at IS NULL OR expires_at >= CURRENT_DATE)
                AND is_active = true
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY COALESCE(discount_amount, discount_percentage) DESC
            """, (current_user.id,))
            referral_coupons = cursor.fetchall()
            
            # Get bonus/public coupons
            cursor.execute("""
                SELECT code, discount_value as discount_percent, min_order_amount as min_order_value,
                       max_discount_amount as max_discount, created_at as valid_from,
                       COALESCE(valid_until, created_at + INTERVAL '30 days') as valid_until,
                       usage_limit, times_used
                FROM coupons
                WHERE user_id IS NULL
                AND is_active = true
                AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
                AND (usage_limit IS NULL OR times_used < usage_limit)
                ORDER BY discount_value DESC
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
            'phone': '+91 7075077384',
            'email': 'sreekanth.chityala@gspaces.in',
            'address': 'Hyderabad, Telangana, India',
            'support_hours': 'Monday - Saturday: 9:00 AM - 6:00 PM IST',
            'whatsapp': '+91 7075077384'
        })
    
    @app.route('/chatbot/orders', methods=['GET'])
    @login_required
    def chatbot_orders():
        """Get user's orders with smart filtering"""
        try:
            # Get filter parameters
            filter_type = request.args.get('filter', 'recent')  # recent, current_month, last_20_days, pending
            offset = int(request.args.get('offset', 0))
            limit = int(request.args.get('limit', 5))
            
            conn = connect_to_db()
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Build query based on filter
            base_query = """
                SELECT id, razorpay_order_id, total_amount, status, order_date
                FROM orders
                WHERE user_id = %s
            """
            params = [current_user.id]
            
            if filter_type == 'pending':
                base_query += " AND status = 'Pending'"
            elif filter_type == 'current_month':
                base_query += " AND DATE_TRUNC('month', order_date) = DATE_TRUNC('month', CURRENT_DATE)"
            elif filter_type == 'last_20_days':
                base_query += " AND order_date >= CURRENT_DATE - INTERVAL '20 days'"
            
            # Get total count for this filter
            count_query = f"SELECT COUNT(*) as total FROM ({base_query}) as filtered"
            cursor.execute(count_query, params)
            total_count = cursor.fetchone()['total']
            
            # Get paginated orders
            base_query += " ORDER BY order_date DESC LIMIT %s OFFSET %s"
            params.extend([limit, offset])
            cursor.execute(base_query, params)
            orders = cursor.fetchall()
            
            # Count pending orders (always)
            cursor.execute("""
                SELECT COUNT(*) as pending_count
                FROM orders
                WHERE user_id = %s AND status = 'Pending'
            """, (current_user.id,))
            pending_count = cursor.fetchone()['pending_count']
            
            conn.close()
            
            # Format orders
            formatted_orders = []
            for order in orders:
                formatted_orders.append({
                    'id': order['id'],
                    'order_id': order['razorpay_order_id'],
                    'total_amount': float(order['total_amount']),
                    'status': order['status'],
                    'created_at': str(order['order_date']),
                    'is_pending': order['status'] == 'Pending'
                })
            
            has_more = (offset + limit) < total_count
            
            return jsonify({
                'orders': formatted_orders,
                'pending_count': pending_count,
                'total_count': total_count,
                'has_more': has_more,
                'next_offset': offset + limit if has_more else None,
                'filter_type': filter_type
            })
            
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
                SELECT id, razorpay_order_id, total_amount, status, order_date,
                       shipping_address_line_1, shipping_city, shipping_state
                FROM orders
                WHERE razorpay_order_id = %s AND user_id = %s
            """, (order_id, current_user.id))
            
            order = cursor.fetchone()
            conn.close()
            
            if not order:
                return jsonify({'error': 'Order not found'}), 404
            
            shipping_address = f"{order['shipping_address_line_1']}, {order['shipping_city']}, {order['shipping_state']}"
            
            return jsonify({
                'order_id': order['razorpay_order_id'],
                'total_amount': float(order['total_amount']),
                'status': order['status'],
                'created_at': str(order['order_date']),
                'shipping_address': shipping_address
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
                          '📞 Getting contact information\n' +
                          'ℹ️ Learning about GSpaces\n\n' +
                          'How can I assist you today?',
                'quick_replies': ['Show coupons', 'Wallet balance', 'Products under 30k', 'Contact us', 'What is GSpaces?']
            }
        
        # About GSpaces / What is GSpaces
        if any(word in message for word in ['what is gspaces', 'about gspaces', 'why gspaces', 'tell me about']):
            return {
                'type': 'text',
                'message': '🏢 **About GSpaces**\n\n' +
                          'GSpaces is India\'s premier destination for complete desk setup solutions! 🎯\n\n' +
                          '✨ **Why Choose GSpaces?**\n' +
                          '• Complete ready-to-use desk setups\n' +
                          '• Premium ergonomic furniture\n' +
                          '• Free installation & setup\n' +
                          '• Perfect for WFH, office & home\n' +
                          '• Starting from just ₹20,000\n' +
                          '• Transform your workspace into a dream setup!\n\n' +
                          '🎁 **Special Benefits:**\n' +
                          '• Exclusive coupons & discounts\n' +
                          '• Wallet cashback rewards\n' +
                          '• Fast delivery across India\n' +
                          '• Quality guaranteed products\n\n' +
                          'Ready to upgrade your workspace? 🚀',
                'quick_replies': ['Show products', 'Check coupons', 'Contact details']
            }
        
        # Help command
        if message == 'help' or 'help' in message:
            return {
                'type': 'text',
                'message': '🤖 **How can I help you?**\n\n' +
                          '💰 **Budget Search:**\n' +
                          '   • "Show setups under 30k"\n' +
                          '   • "Products between 20k to 40k"\n\n' +
                          '🎫 **Coupons & Offers:**\n' +
                          '   • "Show coupons"\n' +
                          '   • "Available offers"\n\n' +
                          '💳 **Wallet:**\n' +
                          '   • "Wallet balance"\n' +
                          '   • "My wallet"\n\n' +
                          '📦 **Orders:**\n' +
                          '   • "My orders"\n' +
                          '   • "Track order"\n\n' +
                          '📞 **Contact:**\n' +
                          '   • "Contact details"\n' +
                          '   • "Support"\n\n' +
                          'ℹ️ **About:**\n' +
                          '   • "What is GSpaces?"\n' +
                          '   • "Why GSpaces?"',
                'quick_replies': ['Show coupons', 'Wallet balance', 'Products under 30k', 'My orders', 'Contact us']
            }
        
        # Budget range search (between X to Y)
        range_match = re.search(r'between\s+(\d+(?:\.\d+)?)\s*k?\s*(?:to|and|-)\s*(\d+(?:\.\d+)?)\s*k?', message, re.IGNORECASE)
        if range_match:
            min_budget = float(range_match.group(1))
            max_budget = float(range_match.group(2))
            # Handle 'k' suffix
            if 'k' in message.lower():
                min_budget *= 1000
                max_budget *= 1000
            return {
                'type': 'budget_range',
                'min_budget': min_budget,
                'max_budget': max_budget,
                'message': f'Searching for products between ₹{min_budget:,.0f} and ₹{max_budget:,.0f}...',
                'quick_replies': ['Show more', 'Check coupons', 'Contact us']
            }
        
        # Budget/price search - handle k/K for thousands
        budget_match = re.search(r'(\d+(?:\.\d+)?)\s*k\b', message, re.IGNORECASE)
        if budget_match and any(word in message for word in ['budget', 'price', 'under', 'within', 'afford', 'cost', 'setup', 'setups', 'show', 'find']):
            budget = float(budget_match.group(1)) * 1000
            return {
                'type': 'budget_search',
                'budget': budget,
                'message': f'Let me find products within ₹{budget:,.0f} for you...',
                'quick_replies': ['Show more', 'Check coupons', 'Wallet balance']
            }
        
        # Regular budget search without 'k'
        budget_match = re.search(r'(\d+)\s*(rupees?|rs\.?|inr|₹)?', message)
        if budget_match and any(word in message for word in ['budget', 'price', 'under', 'within', 'afford', 'cost']):
            budget = float(budget_match.group(1))
            return {
                'type': 'budget_search',
                'budget': budget,
                'message': f'Let me find products within ₹{budget:,.0f} for you...',
                'quick_replies': ['Show more', 'Check coupons', 'Contact us']
            }
        
        # Wallet inquiry
        if any(word in message for word in ['wallet', 'balance', 'money', 'credit']):
            if current_user.is_authenticated:
                return {
                    'type': 'wallet',
                    'message': 'Fetching your wallet information...',
                    'quick_replies': ['Check coupons', 'My orders', 'Products under 30k']
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your wallet balance.',
                    'quick_replies': ['Show products', 'Contact us']
                }
        
        # Coupon inquiry
        if any(word in message for word in ['coupon', 'discount', 'offer', 'promo', 'code']):
            if current_user.is_authenticated:
                return {
                    'type': 'coupons',
                    'message': 'Here are your available coupons...',
                    'quick_replies': ['Wallet balance', 'Products under 30k', 'My orders']
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your coupons.',
                    'quick_replies': ['Show products', 'Contact us']
                }
        
        # Contact inquiry
        if any(word in message for word in ['contact', 'phone', 'email', 'address', 'reach', 'support']):
            return {
                'type': 'contact',
                'message': 'Here\'s how you can reach us...',
                'quick_replies': ['Show products', 'Check coupons', 'What is GSpaces?']
            }
        
        # Order tracking with smart filtering
        if any(word in message for word in ['order', 'track', 'delivery', 'shipping', 'status']):
            if current_user.is_authenticated:
                # Detect filter type from message
                filter_type = 'recent'
                filter_message = 'Let me fetch your recent orders...'
                
                if any(word in message for word in ['pending', 'not delivered', 'undelivered']):
                    filter_type = 'pending'
                    filter_message = 'Fetching your pending orders...'
                elif any(word in message for word in ['current month', 'this month', 'monthly']):
                    filter_type = 'current_month'
                    filter_message = 'Fetching orders from current month...'
                elif any(word in message for word in ['last 20 days', '20 days', 'recent 20']):
                    filter_type = 'last_20_days'
                    filter_message = 'Fetching orders from last 20 days...'
                
                return {
                    'type': 'orders',
                    'message': filter_message,
                    'filter_type': filter_type,
                    'quick_replies': ['Show all orders', 'Pending only', 'Current month', 'Wallet balance']
                }
            else:
                return {
                    'type': 'text',
                    'message': 'Please log in to view your orders.',
                    'quick_replies': ['Show products', 'Contact us']
                }
        
        # Product inquiry
        if any(word in message for word in ['product', 'desk', 'chair', 'setup', 'furniture', 'office', 'show']):
            return {
                'type': 'text',
                'message': 'We offer a wide range of office furniture and setups! You can:\n\n' +
                          '• Browse our products section\n' +
                          '• Tell me your budget to find suitable options\n' +
                          '• Check available discounts and offers\n\n' +
                          'What would you like to know more about?',
                'quick_replies': ['Products under 30k', 'Between 20k to 40k', 'Check coupons', 'Contact us']
            }
        
        # Default response
        return {
            'type': 'text',
            'message': 'I\'m here to help! You can ask me about:\n\n' +
                      '💰 Products within your budget\n' +
                      '🎫 Available coupons and discounts\n' +
                      '💳 Your wallet balance\n' +
                      '📦 Order tracking\n' +
                      '📞 Contact information\n' +
                      'ℹ️ About GSpaces\n\n' +
                      'Type "help" for more options!',
            'quick_replies': ['Show coupons', 'Wallet balance', 'Products under 30k', 'Contact us', 'Help']
        }

# Made with Bob
