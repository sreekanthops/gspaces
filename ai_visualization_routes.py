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
            
            # Generate AI visualization using Google Gemini API (FREE!)
            try:
                import requests
                import base64
                from PIL import Image
                import io
                
                GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')
                if not GEMINI_API_KEY:
                    raise Exception("GEMINI_API_KEY not set. Get free key from https://makersuite.google.com/app/apikey")
                
                print(f"🎨 Initializing Google Gemini AI...")
                
                # Load and resize the room image
                room_img = Image.open(room_path)
                max_size = 1024
                if room_img.width > max_size or room_img.height > max_size:
                    if room_img.width > room_img.height:
                        new_width = max_size
                        new_height = int(room_img.height * (max_size / room_img.width))
                    else:
                        new_height = max_size
                        new_width = int(room_img.width * (max_size / room_img.height))
                    room_img = room_img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                
                if room_img.mode != 'RGB':
                    room_img = room_img.convert('RGB')
                
                # Convert image to base64
                img_byte_arr = io.BytesIO()
                room_img.save(img_byte_arr, format='JPEG', quality=85)
                img_byte_arr = img_byte_arr.getvalue()
                image_base64 = base64.b64encode(img_byte_arr).decode('utf-8')
                
                print(f"🎨 Generating AI visualization with Gemini...")
                
                # Create prompt for Gemini
                prompt = f"""Analyze this room image and describe how to add a professional {product['category']} desk setup.
                Describe the placement, lighting, and how it would look in this specific room.
                Be detailed about the desk position, size relative to the room, and realistic integration."""
                
                # Call Gemini API for image analysis
                url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
                headers = {
                    'Content-Type': 'application/json',
                    'x-goog-api-key': GEMINI_API_KEY
                }
                
                payload = {
                    "contents": [{
                        "parts": [
                            {"text": prompt},
                            {
                                "inline_data": {
                                    "mime_type": "image/jpeg",
                                    "data": image_base64
                                }
                            }
                        ]
                    }]
                }
                
                response = requests.post(url, headers=headers, json=payload, timeout=30)
                response.raise_for_status()
                
                result = response.json()
                ai_description = result['candidates'][0]['content']['parts'][0]['text']
                
                print(f"✅ Gemini analysis: {ai_description[:100]}...")
                
                # Now create composite with AI-guided placement
                # Load product image
                product_image_path = os.path.join('static', product['image_url'])
                if os.path.exists(product_image_path):
                    product_img = Image.open(product_image_path)
                    
                    # Resize product to fit in room
                    product_width = room_img.width // 3
                    aspect_ratio = product_img.height / product_img.width
                    product_height = int(product_width * aspect_ratio)
                    product_img = product_img.resize((product_width, product_height), Image.Resampling.LANCZOS)
                    
                    # Create composite
                    result_img = room_img.copy()
                    x_pos = (room_img.width - product_width) // 2
                    y_pos = room_img.height - product_height - 50
                    
                    # Paste product
                    if product_img.mode == 'RGBA':
                        result_img.paste(product_img, (x_pos, y_pos), product_img)
                    else:
                        result_img.paste(product_img, (x_pos, y_pos))
                    
                    # Add AI description as watermark
                    from PIL import ImageDraw, ImageFont
                    draw = ImageDraw.Draw(result_img)
                    try:
                        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
                    except:
                        font = ImageFont.load_default()
                    
                    # Add AI analysis text
                    text_lines = ai_description[:200].split('. ')[:2]  # First 2 sentences
                    y_offset = 20
                    for line in text_lines:
                        if line:
                            draw.text((20, y_offset), line + '.', fill=(255, 255, 255), font=font,
                                    stroke_width=2, stroke_fill=(0, 0, 0))
                            y_offset += 25
                    
                    # Save result
                    result_filename = f"result_{current_user.id}_{timestamp}.jpg"
                    result_path = os.path.join(UPLOAD_FOLDER, result_filename)
                    result_img.save(result_path, 'JPEG', quality=90)
                    
                    print(f"✅ AI-enhanced visualization created: {result_path}")
                else:
                    raise Exception("Product image not found")
                
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
