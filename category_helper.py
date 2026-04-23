"""
Helper functions for category management
"""
import psycopg2
from psycopg2.extras import RealDictCursor
import os

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'gspaces'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'sri')
    )

def get_active_categories():
    """
    Fetch all active categories ordered by display_order
    Returns list of category dictionaries
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT id, name, slug, display_order
            FROM categories
            WHERE is_active = TRUE
            ORDER BY display_order ASC, name ASC
        """)
        
        categories = cur.fetchall()
        cur.close()
        conn.close()
        
        return categories
    except Exception as e:
        print(f"Error fetching categories: {e}")
        return []

def inject_categories():
    """
    Context processor to inject categories into all templates
    Use this in Flask app: @app.context_processor
    """
    return dict(categories=get_active_categories())

# Made with Bob
