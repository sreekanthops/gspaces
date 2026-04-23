from flask import render_template, request, redirect, url_for, flash, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
import os

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'gspaces'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'sri')
    )

def register_category_routes(app):
    """Register all category management routes"""
    
    @app.route('/admin/categories')
    def admin_categories():
        """Display category management page"""
        if 'admin_logged_in' not in session:
            return redirect(url_for('admin_login'))
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            cur.execute("""
                SELECT id, name, slug, display_order, is_active, created_at
                FROM categories
                ORDER BY display_order ASC, name ASC
            """)
            categories = cur.fetchall()
            
            return render_template('admin_categories.html', categories=categories)
        except Exception as e:
            flash(f'Error loading categories: {str(e)}', 'error')
            return redirect(url_for('admin_dashboard'))
        finally:
            cur.close()
            conn.close()
    
    @app.route('/admin/categories/add', methods=['POST'])
    def add_category():
        """Add a new category"""
        if 'admin_logged_in' not in session:
            return redirect(url_for('admin_login'))
        
        name = request.form.get('name', '').strip()
        slug = request.form.get('slug', '').strip()
        is_active = 'is_active' in request.form
        
        if not name or not slug:
            flash('Category name and slug are required', 'error')
            return redirect(url_for('admin_categories'))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Get max display_order
            cur.execute("SELECT COALESCE(MAX(display_order), 0) + 1 FROM categories")
            next_order = cur.fetchone()[0]
            
            cur.execute("""
                INSERT INTO categories (name, slug, display_order, is_active)
                VALUES (%s, %s, %s, %s)
            """, (name, slug, next_order, is_active))
            
            conn.commit()
            flash(f'Category "{name}" added successfully!', 'success')
        except psycopg2.IntegrityError:
            conn.rollback()
            flash(f'Category with name "{name}" or slug "{slug}" already exists', 'error')
        except Exception as e:
            conn.rollback()
            flash(f'Error adding category: {str(e)}', 'error')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_categories'))
    
    @app.route('/admin/categories/edit/<int:category_id>', methods=['POST'])
    def edit_category(category_id):
        """Edit an existing category"""
        if 'admin_logged_in' not in session:
            return redirect(url_for('admin_login'))
        
        name = request.form.get('name', '').strip()
        slug = request.form.get('slug', '').strip()
        is_active = 'is_active' in request.form
        
        if not name or not slug:
            flash('Category name and slug are required', 'error')
            return redirect(url_for('admin_categories'))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                UPDATE categories
                SET name = %s, slug = %s, is_active = %s, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (name, slug, is_active, category_id))
            
            conn.commit()
            
            if cur.rowcount > 0:
                flash(f'Category "{name}" updated successfully!', 'success')
            else:
                flash('Category not found', 'error')
        except psycopg2.IntegrityError:
            conn.rollback()
            flash(f'Category with name "{name}" or slug "{slug}" already exists', 'error')
        except Exception as e:
            conn.rollback()
            flash(f'Error updating category: {str(e)}', 'error')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_categories'))
    
    @app.route('/admin/categories/delete/<int:category_id>', methods=['POST'])
    def delete_category(category_id):
        """Delete a category"""
        if 'admin_logged_in' not in session:
            return redirect(url_for('admin_login'))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Check if category has products
            cur.execute("SELECT COUNT(*) FROM products WHERE category_id = %s", (category_id,))
            product_count = cur.fetchone()[0]
            
            if product_count > 0:
                flash(f'Cannot delete category: {product_count} products are using it. Please reassign products first.', 'error')
            else:
                cur.execute("DELETE FROM categories WHERE id = %s", (category_id,))
                conn.commit()
                
                if cur.rowcount > 0:
                    flash('Category deleted successfully!', 'success')
                else:
                    flash('Category not found', 'error')
        except Exception as e:
            conn.rollback()
            flash(f'Error deleting category: {str(e)}', 'error')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_categories'))
    
    @app.route('/admin/categories/toggle/<int:category_id>', methods=['POST'])
    def toggle_category(category_id):
        """Toggle category active status"""
        if 'admin_logged_in' not in session:
            return redirect(url_for('admin_login'))
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                UPDATE categories
                SET is_active = NOT is_active, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (category_id,))
            
            conn.commit()
            flash('Category status updated!', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error toggling category: {str(e)}', 'error')
        finally:
            cur.close()
            conn.close()
        
        return redirect(url_for('admin_categories'))
    
    @app.route('/admin/categories/reorder', methods=['POST'])
    def reorder_categories():
        """Update category display order"""
        if 'admin_logged_in' not in session:
            return jsonify({'success': False, 'error': 'Unauthorized'}), 401
        
        order_data = request.json.get('order', [])
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            for item in order_data:
                cur.execute("""
                    UPDATE categories
                    SET display_order = %s, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (item['order'], item['id']))
            
            conn.commit()
            return jsonify({'success': True})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'error': str(e)}), 500
        finally:
            cur.close()
            conn.close()
    
    @app.route('/api/categories')
    def get_categories_api():
        """API endpoint to get all active categories"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            cur.execute("""
                SELECT id, name, slug, display_order
                FROM categories
                WHERE is_active = TRUE
                ORDER BY display_order ASC, name ASC
            """)
            categories = cur.fetchall()
            return jsonify({'success': True, 'categories': categories})
        except Exception as e:
            return jsonify({'success': False, 'error': str(e)}), 500
        finally:
            cur.close()
            conn.close()

# Made with Bob
