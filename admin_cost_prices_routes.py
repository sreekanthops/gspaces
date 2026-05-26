"""
Admin Cost Prices Management Routes
Allows admins to set and manage cost prices for profit analysis
"""

from flask import Blueprint, render_template, request, jsonify
from flask_login import login_required, current_user
from functools import wraps
from psycopg2.extras import RealDictCursor

# Create blueprint
admin_cost_prices_bp = Blueprint('admin_cost_prices', __name__)

# Database connection function (will be set from main.py)
_db_connection_func = None

def set_db_connection_func(func):
    """Set the database connection function"""
    global _db_connection_func
    _db_connection_func = func

def get_db_connection():
    """Get database connection"""
    if _db_connection_func is None:
        raise RuntimeError("Database connection function not set")
    return _db_connection_func()


def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        if not current_user.is_admin:
            return jsonify({'success': False, 'message': 'Admin access required'}), 403
        return f(*args, **kwargs)
    return decorated_function


@admin_cost_prices_bp.route('/admin/cost-prices')
@admin_required
def cost_prices_page():
    """Render cost prices management page"""
    return render_template('admin_cost_prices.html')


@admin_cost_prices_bp.route('/admin/api/cost-prices')
@admin_required
def get_cost_prices():
    """Get all items with their cost prices"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get all default items with their cost prices
        cur.execute("""
            SELECT 
                id,
                name,
                item_slug,
                category,
                price,
                cost_price,
                icon_image
            FROM default_items
            ORDER BY category, name
        """)
        
        items = cur.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'items': [dict(item) for item in items]
        })
        
    except Exception as e:
        print(f"Error fetching cost prices: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


@admin_cost_prices_bp.route('/admin/api/cost-prices/update', methods=['POST'])
@admin_required
def update_cost_price():
    """Update cost price for a single item"""
    try:
        data = request.get_json()
        item_id = data.get('item_id')
        cost_price = float(data.get('cost_price', 0))
        
        if not item_id:
            return jsonify({
                'success': False,
                'message': 'Item ID is required'
            }), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Update cost price
        cur.execute("""
            UPDATE default_items
            SET cost_price = %s
            WHERE id = %s
        """, (cost_price, item_id))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'Cost price updated successfully'
        })
        
    except Exception as e:
        print(f"Error updating cost price: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


@admin_cost_prices_bp.route('/admin/api/cost-prices/bulk-update', methods=['POST'])
@admin_required
def bulk_update_cost_prices():
    """Update cost prices for multiple items"""
    try:
        data = request.get_json()
        updates = data.get('updates', [])
        
        if not updates:
            return jsonify({
                'success': False,
                'message': 'No updates provided'
            }), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        updated_count = 0
        for update in updates:
            item_id = update.get('item_id')
            cost_price = float(update.get('cost_price', 0))
            
            if item_id:
                cur.execute("""
                    UPDATE default_items
                    SET cost_price = %s
                    WHERE id = %s
                """, (cost_price, item_id))
                updated_count += 1
        
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': f'Updated {updated_count} cost prices',
            'updated_count': updated_count
        })
        
    except Exception as e:
        print(f"Error bulk updating cost prices: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


@admin_cost_prices_bp.route('/admin/api/cost-prices/item/<item_slug>')
@admin_required
def get_item_cost_price(item_slug):
    """Get cost price for a specific item by slug"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT cost_price, price
            FROM default_items
            WHERE item_slug = %s
        """, (item_slug,))
        
        item = cur.fetchone()
        conn.close()
        
        if item:
            return jsonify({
                'success': True,
                'cost_price': float(item['cost_price'] or 0),
                'selling_price': float(item['price'] or 0)
            })
        else:
            return jsonify({
                'success': False,
                'message': 'Item not found'
            }), 404
        
    except Exception as e:
        print(f"Error fetching item cost price: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


# Export blueprint registration function
def register_admin_cost_prices_routes(app, db_connection_func):
    """Register admin cost prices routes with the Flask app"""
    set_db_connection_func(db_connection_func)
    app.register_blueprint(admin_cost_prices_bp)
    print("✅ Admin Cost Prices routes registered")


# Made with Bob