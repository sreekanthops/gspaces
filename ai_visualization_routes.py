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
            
            # Generate AI visualization using Leonardo.ai (FREE TIER AVAILABLE!)
            try:
                import requests
                from PIL import Image
                import time
                
                LEONARDO_API_KEY = os.environ.get('LEONARDO_API_KEY', '')
                if not LEONARDO_API_KEY:
                    raise Exception("LEONARDO_API_KEY not set. Get free key from https://leonardo.ai")
                
                print(f"🎨 Using Leonardo.ai for AI image generation (FREE tier available!)...")
                
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
                
                # Save as JPG for Leonardo upload
                base_image.save(room_path, format="JPEG", quality=90)
                
                # Create transformation prompt
                prompt = f"""Transform this room into a professional {product['category']} setup with a modern {product['name']},
                cinematic lighting, photorealistic, high quality interior design, realistic shadows and reflections,
                naturally integrated furniture"""
                
                print(f"🎨 Generating AI transformation with Leonardo.ai...")
                print(f"📝 Prompt: {prompt[:100]}...")
                
                # Leonardo API headers
                headers = {
                    "accept": "application/json",
                    "content-type": "application/json",
                    "authorization": f"Bearer {LEONARDO_API_KEY}"
                }
                
                # STEP 1: Get upload URL
                print(f"📤 Step 1: Requesting upload slot...")
                upload_url_endpoint = "https://cloud.leonardo.ai/api/rest/v1/init-image"
                upload_payload = {"extension": "jpg"}
                upload_response = requests.post(upload_url_endpoint, json=upload_payload, headers=headers).json()
                
                if 'uploadInitImage' not in upload_response:
                    raise Exception(f"Failed to get upload URL: {upload_response}")
                
                upload_data = upload_response['uploadInitImage']
                upload_url = upload_data['url']
                image_id = upload_data['id']
                upload_fields = upload_data.get('fields', {})
                
                print(f"✅ Got upload URL and image ID: {image_id}")
                print(f"📋 Upload fields: {upload_fields}")
                
                # STEP 2: Upload image to S3
                print(f"📤 Step 2: Uploading image...")
                with open(room_path, "rb") as f:
                    image_data = f.read()
                
                # If there are fields, use POST with multipart/form-data
                if upload_fields:
                    print(f"🔄 Using POST with form fields...")
                    # Convert fields to proper format (not JSON string)
                    form_data = {}
                    if isinstance(upload_fields, str):
                        import json
                        form_data = json.loads(upload_fields)
                    else:
                        form_data = upload_fields
                    
                    files = {'file': ('image.jpg', image_data, 'image/jpeg')}
                    upload_result = requests.post(upload_url, data=form_data, files=files)
                else:
                    # Otherwise use PUT
                    print(f"🔄 Using PUT...")
                    upload_headers = {"Content-Type": "image/jpeg"}
                    upload_result = requests.put(upload_url, data=image_data, headers=upload_headers)
                
                if upload_result.status_code not in [200, 201, 204]:
                    print(f"⚠️  Upload failed with status {upload_result.status_code}")
                    print(f"⚠️  Response: {upload_result.text[:500]}")
                    raise Exception(f"Failed to upload image: {upload_result.status_code}")
                print(f"✅ Image uploaded successfully")
                
                # STEP 3: Trigger generation
                print(f"🎨 Step 3: Starting AI transformation...")
                gen_url = "https://cloud.leonardo.ai/api/rest/v1/generations"
                gen_payload = {
                    "height": new_height if 'new_height' in locals() else base_image.height,
                    "width": new_width if 'new_width' in locals() else base_image.width,
                    "modelId": "6bef9f1b-29cb-40c7-b9df-cd93b0fab2ec",  # Leonardo Vision XL
                    "prompt": prompt,
                    "init_image_id": image_id,
                    "init_strength": 0.4,  # Balance between original and transformation
                    "num_images": 1
                }
                
                gen_response = requests.post(gen_url, json=gen_payload, headers=headers).json()
                
                if 'sdGenerationJob' not in gen_response:
                    raise Exception(f"Failed to start generation: {gen_response}")
                
                generation_id = gen_response['sdGenerationJob']['generationId']
                print(f"✅ Generation started with ID: {generation_id}")
                
                # STEP 4: Poll for completion
                print(f"⏳ Step 4: Waiting for image to process...")
                status_url = f"https://cloud.leonardo.ai/api/rest/v1/generations/{generation_id}"
                
                max_attempts = 60  # 3 minutes max
                attempt = 0
                generated_image_url = None
                
                while attempt < max_attempts:
                    time.sleep(3)
                    attempt += 1
                    
                    status_response = requests.get(status_url, headers=headers).json()
                    
                    if 'generations_by_pk' not in status_response:
                        print(f"⚠️  Unexpected response: {status_response}")
                        continue
                    
                    job = status_response['generations_by_pk']
                    status = job.get('status', 'UNKNOWN')
                    
                    if status == "COMPLETE":
                        if 'generated_images' in job and len(job['generated_images']) > 0:
                            generated_image_url = job['generated_images'][0]['url']
                            print(f"✅ AI transformation complete!")
                            print(f"📥 Downloading from: {generated_image_url}")
                            break
                        else:
                            raise Exception("Generation complete but no images found")
                    elif status == "FAILED":
                        raise Exception(f"Generation failed: {job.get('message', 'Unknown error')}")
                    else:
                        print(f".", end="", flush=True)
                
                if attempt >= max_attempts or generated_image_url is None:
                    raise Exception("Generation timed out after 3 minutes")
                
                # Download the generated image
                image_response = requests.get(generated_image_url, timeout=30)
                
                if image_response.status_code != 200:
                    raise Exception(f"Failed to download generated image: {image_response.status_code}")
                
                successful_model = "leonardo-vision-xl"
                
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
