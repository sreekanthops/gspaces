"""
AI Room Visualization Routes
Allows users to upload their room photo and see desk setups placed in their space
Uses Replicate API for AI image generation
"""

from flask import Blueprint, request, jsonify, render_template, session
from flask_login import login_required, current_user
import os
from PIL import Image
import io
import base64
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

# Try to import replicate, but don't fail if not installed
try:
    import replicate
    REPLICATE_AVAILABLE = True
except ImportError:
    REPLICATE_AVAILABLE = False
    print("⚠️  Warning: replicate module not installed. Install with: pip install replicate")

# Configuration
REPLICATE_API_TOKEN = os.environ.get('REPLICATE_API_TOKEN', '')  # Set in environment
UPLOAD_FOLDER = 'static/uploads/visualizations'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'gspaces'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', '')
    )

def register_ai_routes(app):
    """Register all AI visualization routes"""
    
    print("🎨 Registering AI visualization routes...")
    
    @app.route('/visualize/<int:product_id>')
    @login_required
    def visualize_product(product_id):
        print(f"📸 Visualize route called for product {product_id}")
        """Show visualization page for a product"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get product details
        cur.execute("""
            SELECT id, name, description, price, image_url, category
            FROM products
            WHERE id = %s
        """, (product_id,))
        product = cur.fetchone()
        
        if not product:
            cur.close()
            conn.close()
            return "Product not found", 404
        
        # Get user's previous visualizations for this product
        cur.execute("""
            SELECT id, room_image_url, result_image_url, created_at
            FROM room_visualizations
            WHERE user_id = %s AND product_id = %s
            ORDER BY created_at DESC
            LIMIT 5
        """, (current_user.id, product_id))
        previous_visualizations = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return render_template('visualize_room.html', 
                             product=product,
                             previous_visualizations=previous_visualizations)
    
    @app.route('/api/visualize/generate', methods=['POST'])
    @login_required
    def generate_visualization():
        """Generate AI visualization of product in user's room"""
        try:
            # Check if Replicate API token is set
            if not REPLICATE_API_TOKEN:
                return jsonify({
                    'status': 'error',
                    'message': 'AI service not configured. Please contact administrator.'
                }), 500
            
            # Get form data
            product_id = request.form.get('product_id')
            room_image = request.files.get('room_image')
            
            if not product_id or not room_image:
                return jsonify({
                    'status': 'error',
                    'message': 'Missing required fields'
                }), 400
            
            # Get product details
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT id, name, image_url, category
                FROM products
                WHERE id = %s
            """, (product_id,))
            product = cur.fetchone()
            
            if not product:
                cur.close()
                conn.close()
                return jsonify({
                    'status': 'error',
                    'message': 'Product not found'
                }), 404
            
            # Save room image
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            room_filename = f"room_{current_user.id}_{timestamp}.jpg"
            room_path = os.path.join(UPLOAD_FOLDER, room_filename)
            room_image.save(room_path)
            
            # Prepare product image path
            product_image_path = product['image_url']
            if product_image_path.startswith('static/'):
                product_image_path = product_image_path[7:]  # Remove 'static/' prefix
            
            # Generate AI visualization using Replicate
            # Using Stable Diffusion Inpainting model
            output = replicate.run(
                "stability-ai/stable-diffusion:db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf",
                input={
                    "image": open(room_path, "rb"),
                    "prompt": f"professional {product['category']} desk setup in room, realistic lighting, natural placement, high quality furniture, modern interior design",
                    "negative_prompt": "blurry, distorted, unrealistic, low quality, cartoon, painting, drawing",
                    "num_outputs": 1,
                    "guidance_scale": 7.5,
                    "num_inference_steps": 50
                }
            )
            
            # Save result image
            result_filename = f"result_{current_user.id}_{timestamp}.jpg"
            result_path = os.path.join(UPLOAD_FOLDER, result_filename)
            
            # Download and save the result
            import requests
            result_url = output[0] if isinstance(output, list) else output
            response = requests.get(result_url)
            with open(result_path, 'wb') as f:
                f.write(response.content)
            
            # Save to database
            cur.execute("""
                INSERT INTO room_visualizations 
                (user_id, product_id, room_image_url, result_image_url, created_at)
                VALUES (%s, %s, %s, %s, NOW())
                RETURNING id
            """, (
                current_user.id,
                product_id,
                f"uploads/visualizations/{room_filename}",
                f"uploads/visualizations/{result_filename}"
            ))
            visualization_id = cur.fetchone()['id']
            
            conn.commit()
            cur.close()
            conn.close()
            
            return jsonify({
                'status': 'success',
                'visualization_id': visualization_id,
                'result_image_url': f"/static/uploads/visualizations/{result_filename}",
                'message': 'Visualization generated successfully!'
            })
            
        except Exception as e:
            print(f"Error generating visualization: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to generate visualization: {str(e)}'
            }), 500
    
    @app.route('/api/visualize/history')
    @login_required
    def get_visualization_history():
        """Get user's visualization history"""
        try:
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            cur.execute("""
                SELECT 
                    v.id,
                    v.product_id,
                    p.name as product_name,
                    v.room_image_url,
                    v.result_image_url,
                    v.created_at
                FROM room_visualizations v
                JOIN products p ON v.product_id = p.id
                WHERE v.user_id = %s
                ORDER BY v.created_at DESC
                LIMIT 20
            """, (current_user.id,))
            
            visualizations = cur.fetchall()
            
            cur.close()
            conn.close()
            
            return jsonify({
                'status': 'success',
                'visualizations': visualizations
            })
            
        except Exception as e:
            return jsonify({
                'status': 'error',
                'message': str(e)
            }), 500
    
    @app.route('/api/visualize/delete/<int:visualization_id>', methods=['DELETE'])
    @login_required
    def delete_visualization(visualization_id):
        """Delete a visualization"""
        try:
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Check ownership
            cur.execute("""
                SELECT room_image_url, result_image_url
                FROM room_visualizations
                WHERE id = %s AND user_id = %s
            """, (visualization_id, current_user.id))
            
            visualization = cur.fetchone()
            
            if not visualization:
                cur.close()
                conn.close()
                return jsonify({
                    'status': 'error',
                    'message': 'Visualization not found'
                }), 404
            
            # Delete files
            try:
                if visualization['room_image_url']:
                    room_path = os.path.join('static', visualization['room_image_url'])
                    if os.path.exists(room_path):
                        os.remove(room_path)
                
                if visualization['result_image_url']:
                    result_path = os.path.join('static', visualization['result_image_url'])
                    if os.path.exists(result_path):
                        os.remove(result_path)
            except Exception as e:
                print(f"Error deleting files: {str(e)}")
            
            # Delete from database
            cur.execute("""
                DELETE FROM room_visualizations
                WHERE id = %s AND user_id = %s
            """, (visualization_id, current_user.id))
            
            conn.commit()
            cur.close()
            conn.close()
            
            return jsonify({
                'status': 'success',
                'message': 'Visualization deleted successfully'
            })
            
        except Exception as e:
            return jsonify({
                'status': 'error',
                'message': str(e)
            }), 500

    print("✅ AI Visualization routes registered")

# Made with Bob
