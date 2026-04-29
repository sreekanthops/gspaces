"""
AI Room Visualization Routes
Allows users to upload their room photo and see desk setups placed in their space
Uses ModelsLab API for AI image generation
"""

from flask import Blueprint, request, jsonify, render_template, session
from flask_login import login_required, current_user
import os
from PIL import Image
import io
import base64
import json
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
        try:
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Get product details
            cur.execute("""
                SELECT id, name, description, price, image_url, category
                FROM products
                WHERE id = %s
            """, (product_id,))
            product = cur.fetchone()
            
            print(f"🔍 Product query result: {product}")
            
            if not product:
                print(f"❌ Product {product_id} not found in database")
                cur.close()
                conn.close()
                return "Product not found", 404
        except Exception as e:
            print(f"❌ Database error: {e}")
            return f"Database error: {e}", 500
        
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
            
            # Generate AI visualization using ModelsLab (Image-guided editing!)
            try:
                import requests
                from PIL import Image
                import time
                
                MODELSLAB_API_KEY = os.environ.get('MODELSLAB_API_KEY', '')
                if not MODELSLAB_API_KEY:
                    raise Exception("MODELSLAB_API_KEY not set. Get key from https://modelslab.com")
                
                print(f"🎨 Using ModelsLab for AI image generation with control_image!")
                
                # Load the room image
                print(f"📸 Loading room image...")
                base_image = Image.open(room_path)
                
                # Resize if needed (Leonardo works well with 768-1024)
                max_size = 1024
                new_width = base_image.width
                new_height = base_image.height
                
                if base_image.width > max_size or base_image.height > max_size:
                    if base_image.width > base_image.height:
                        new_width = max_size
                        new_height = int(base_image.height * (max_size / base_image.width))
                    else:
                        new_height = max_size
                        new_width = int(base_image.width * (max_size / base_image.height))
                    base_image = base_image.resize((new_width, new_height), Image.Resampling.LANCZOS)
                    print(f"✅ Resized to {new_width}x{new_height}")
                
                if base_image.mode != 'RGB':
                    base_image = base_image.convert('RGB')
                
                # Save as JPG
                base_image.save(room_path, format="JPEG", quality=90)
                
                # Get product image URL
                product_image_url = f"{request.url_root}static/{product['image_url']}" if not product['image_url'].startswith('http') else product['image_url']
                room_image_url = f"{request.url_root}static/uploads/visualizations/{os.path.basename(room_path)}"
                
                # Create transformation prompt
                prompt = f"""Apply the furniture and desk setup from the reference image to this empty room.
                Place a {product['name']} ({product['category']}) in the room with realistic lighting,
                shadows, and perspective. Professional interior design, photorealistic, high quality."""
                
                print(f"\n{'='*60}")
                print(f"🎨 MODELSLAB AI VISUALIZATION")
                print(f"{'='*60}")
                print(f"📦 Product: {product['name']}")
                print(f"📸 Room Image: {room_image_url}")
                print(f"🖼️  Control Image (Product): {product_image_url}")
                print(f"📝 Prompt: {prompt}")
                print(f"{'='*60}\n")
                
                # ModelsLab API call - v7 image-to-image endpoint
                print(f"🎨 Calling ModelsLab API v7...")
                MODELSLAB_URL = "https://modelslab.com/api/v7/images/image-to-image"
                
                headers = {
                    "Content-Type": "application/json"
                }
                
                # Use both images: room as base, product as reference
                payload = {
                    "init_image": [
                        room_image_url,      # Base image (empty room)
                        product_image_url    # Reference image (product to add)
                    ],
                    "prompt": prompt,
                    "model_id": "gpt-image-2-i2i",  # GPT Image 2 model for image-to-image
                    "size": f"{new_width}x{new_height}",
                    "key": MODELSLAB_API_KEY
                }
                
                print(f"📤 Sending request to ModelsLab v7...")
                print(f"📊 Payload: {json.dumps(payload, indent=2)}")
                api_response = requests.post(MODELSLAB_URL, headers=headers, json=payload, timeout=120)
                
                if api_response.status_code != 200:
                    raise Exception(f"ModelsLab API failed: {api_response.status_code} - {api_response.text}")
                
                result_data = api_response.json()
                print(f"📥 Response: {result_data}")
                
                # Get generated image URL
                if result_data.get('status') == 'success' and 'output' in result_data:
                    generated_image_url = result_data['output'][0] if isinstance(result_data['output'], list) else result_data['output']
                    print(f"✅ AI transformation complete!")
                elif 'future_links' in result_data:
                    # Image is processing, need to poll
                    fetch_url = result_data['future_links'][0]
                    print(f"⏳ Image processing, polling for result...")
                    
                    max_attempts = 30
                    for attempt in range(max_attempts):
                        time.sleep(3)
                        fetch_response = requests.get(fetch_url)
                        fetch_data = fetch_response.json()
                        
                        if fetch_data.get('status') == 'success' and 'output' in fetch_data:
                            generated_image_url = fetch_data['output'][0] if isinstance(fetch_data['output'], list) else fetch_data['output']
                            print(f"✅ AI transformation complete!")
                            break
                        elif fetch_data.get('status') == 'failed':
                            raise Exception(f"Generation failed: {fetch_data.get('message', 'Unknown error')}")
                        else:
                            print(f".", end="", flush=True)
                    else:
                        raise Exception("Generation timed out")
                else:
                    raise Exception(f"Unexpected response: {result_data}")
                
                # Download generated image
                print(f"📥 Downloading from: {generated_image_url}")
                image_response = requests.get(generated_image_url, timeout=30)
                
                if image_response.status_code != 200:
                    raise Exception(f"Failed to download: {image_response.status_code}")
                
                successful_model = "modelslab-sdxl"
                
                
                # Save the edited image from Pixazo response
                result_filename = f"result_{current_user.id}_{timestamp}.png"
                result_path = os.path.join(UPLOAD_FOLDER, result_filename)
                
                # Save the downloaded image
                with open(result_path, 'wb') as f:
                    f.write(image_response.content)
                print(f"✅ AI-edited image saved: {result_path}")
                
            except ImportError:
                print("⚠️  huggingface_hub not installed, using fallback...")
                # Fallback: use product image
                import shutil
                product_image_path = os.path.join('static', product['image_url'])
                result_filename = f"result_{current_user.id}_{timestamp}.jpg"
                result_path = os.path.join(UPLOAD_FOLDER, result_filename)
                if os.path.exists(product_image_path):
                    shutil.copy(product_image_path, result_path)
                else:
                    raise Exception("Product image not found")
            except Exception as e:
                print(f"❌ AI generation failed: {e}")
                raise
            
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
            result = cur.fetchone()
            visualization_id = result['id'] if result else None
            
            if not visualization_id:
                raise Exception("Failed to save visualization to database")
            
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
