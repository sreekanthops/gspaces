"""
Customer Blog System Routes
Allows customers to share their desk setup experiences with images and videos
"""

from flask import render_template, request, redirect, url_for, flash, jsonify, session
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
import os
from datetime import datetime
import bleach
import uuid

# Allowed HTML tags for blog content (for security)
ALLOWED_TAGS = [
    'p', 'br', 'strong', 'em', 'u', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'ul', 'ol', 'li', 'blockquote', 'code', 'pre', 'a', 'img'
]

ALLOWED_ATTRIBUTES = {
    'a': ['href', 'title'],
    'img': ['src', 'alt', 'title']
}

# File upload configuration
BLOG_UPLOAD_FOLDER = 'static/img/blogs'
ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
ALLOWED_VIDEO_EXTENSIONS = {'mp4', 'webm', 'mov'}
MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5MB
MAX_VIDEO_SIZE = 50 * 1024 * 1024  # 50MB
MAX_VIDEO_DURATION = 60  # 60 seconds

def allowed_file(filename, file_type='image'):
    if '.' not in filename:
        return False
    ext = filename.rsplit('.', 1)[1].lower()
    if file_type == 'image':
        return ext in ALLOWED_IMAGE_EXTENSIONS
    elif file_type == 'video':
        return ext in ALLOWED_VIDEO_EXTENSIONS
    return False

def sanitize_html(content):
    """Sanitize HTML content to prevent XSS attacks"""
    return bleach.clean(content, tags=ALLOWED_TAGS, attributes=ALLOWED_ATTRIBUTES, strip=True)

def add_blog_routes(app, connect_to_db):
    """Add blog routes to the Flask app"""
    
    # Ensure upload directory exists
    os.makedirs(BLOG_UPLOAD_FOLDER, exist_ok=True)
    
    # -----------------------
    # BLOG LISTING PAGE
    # -----------------------
    @app.route('/blogs')
    def blogs():
        """Display all approved customer blogs"""
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('index'))
        
        try:
            cur = conn.cursor()
            
            # Get filter and sort parameters
            sort_by = request.args.get('sort', 'recent')  # recent, popular, liked
            
            # Build query based on sort
            if sort_by == 'popular':
                order_clause = "cb.views DESC"
            elif sort_by == 'reactions':
                order_clause = "reaction_count DESC"
            else:  # recent
                order_clause = "cb.created_at DESC"
            
            query = f"""
                SELECT
                    cb.id, cb.title, cb.content, cb.views, cb.created_at,
                    u.name as author_name, u.email as author_email,
                    COUNT(DISTINCT br.id) as reaction_count,
                    COUNT(DISTINCT bc.id) as comment_count,
                    (SELECT media_url FROM blog_media WHERE blog_id = cb.id AND media_type = 'image' ORDER BY media_order LIMIT 1) as thumbnail
                FROM customer_blogs cb
                JOIN users u ON cb.user_id = u.id
                LEFT JOIN blog_reactions br ON cb.id = br.blog_id
                LEFT JOIN blog_comments bc ON cb.id = bc.blog_id
                WHERE cb.status = 'approved'
                GROUP BY cb.id, u.name, u.email
                ORDER BY {order_clause}
            """
            
            cur.execute(query)
            blogs = cur.fetchall()
            
            cur.close()
            conn.close()
            
            return render_template('blogs.html', blogs=blogs, sort_by=sort_by)
            
        except Exception as e:
            print(f"Error fetching blogs: {e}")
            flash('Error loading blogs', 'error')
            return redirect(url_for('index'))
    
    # -----------------------
    # BLOG DETAIL PAGE
    # -----------------------
    @app.route('/blog/<int:blog_id>')
    def blog_detail(blog_id):
        """Display single blog with all details"""
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('blogs'))
        
        try:
            cur = conn.cursor()
            
            # Get blog details with reaction counts
            cur.execute("""
                SELECT
                    cb.id, cb.title, cb.content, cb.views, cb.created_at, cb.user_id,
                    u.name as author_name, u.email as author_email,
                    COUNT(DISTINCT br.id) as total_reactions,
                    COUNT(DISTINCT bc.id) as comment_count
                FROM customer_blogs cb
                JOIN users u ON cb.user_id = u.id
                LEFT JOIN blog_reactions br ON cb.id = br.blog_id
                LEFT JOIN blog_comments bc ON cb.id = bc.blog_id
                WHERE cb.id = %s AND cb.status = 'approved'
                GROUP BY cb.id, u.name, u.email
            """, (blog_id,))
            
            blog = cur.fetchone()
            
            if not blog:
                flash('Blog not found', 'error')
                return redirect(url_for('blogs'))
            
            # Increment view count
            cur.execute("UPDATE customer_blogs SET views = views + 1 WHERE id = %s", (blog_id,))
            conn.commit()
            
            # Get blog media
            cur.execute("""
                SELECT id, media_type, media_url, media_order
                FROM blog_media
                WHERE blog_id = %s
                ORDER BY media_order
            """, (blog_id,))
            media = cur.fetchall()
            
            # Get comments
            cur.execute("""
                SELECT bc.id, bc.comment, bc.created_at, u.name as commenter_name
                FROM blog_comments bc
                JOIN users u ON bc.user_id = u.id
                WHERE bc.blog_id = %s
                ORDER BY bc.created_at DESC
            """, (blog_id,))
            comments = cur.fetchall()
            
            # Get reaction counts by type
            cur.execute("""
                SELECT reaction_type, COUNT(*) as count
                FROM blog_reactions
                WHERE blog_id = %s
                GROUP BY reaction_type
            """, (blog_id,))
            reactions = {row[0]: row[1] for row in cur.fetchall()}
            
            # Get user's reactions (if any)
            user_reactions = []
            session_id = session.get('session_id')
            if current_user.is_authenticated:
                cur.execute("""
                    SELECT reaction_type FROM blog_reactions
                    WHERE blog_id = %s AND user_id = %s
                """, (blog_id, current_user.id))
                user_reactions = [row[0] for row in cur.fetchall()]
            elif session_id:
                cur.execute("""
                    SELECT reaction_type FROM blog_reactions
                    WHERE blog_id = %s AND session_id = %s
                """, (blog_id, session_id))
                user_reactions = [row[0] for row in cur.fetchall()]
            
            cur.close()
            conn.close()
            
            return render_template('blog_detail.html',
                                 blog=blog,
                                 media=media,
                                 comments=comments,
                                 reactions=reactions,
                                 user_reactions=user_reactions)
            
        except Exception as e:
            print(f"Error fetching blog detail: {e}")
            flash('Error loading blog', 'error')
            return redirect(url_for('blogs'))
    
    # -----------------------
    # CREATE BLOG
    # -----------------------
    @app.route('/blog/create', methods=['GET', 'POST'])
    @login_required
    def create_blog():
        """Create a new blog post"""
        if request.method == 'GET':
            return render_template('create_blog.html')
        
        # POST request - handle blog creation
        title = request.form.get('title', '').strip()
        content = request.form.get('content', '').strip()
        
        if not title or not content:
            flash('Title and content are required', 'error')
            return redirect(url_for('create_blog'))
        
        if len(title) > 255:
            flash('Title is too long (max 255 characters)', 'error')
            return redirect(url_for('create_blog'))
        
        # Sanitize HTML content
        content = sanitize_html(content)
        
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('create_blog'))
        
        try:
            cur = conn.cursor()
            
            # Insert blog
            cur.execute("""
                INSERT INTO customer_blogs (user_id, title, content, status)
                VALUES (%s, %s, %s, 'pending')
                RETURNING id
            """, (current_user.id, title, content))
            
            blog_id = cur.fetchone()[0]
            
            # Handle file uploads
            uploaded_files = []
            
            # Handle images (up to 2)
            images = request.files.getlist('images')
            image_count = 0
            for img in images:
                if img and img.filename and image_count < 2:
                    if allowed_file(img.filename, 'image'):
                        filename = secure_filename(f"blog_{blog_id}_{image_count}_{datetime.now().strftime('%Y%m%d%H%M%S')}_{img.filename}")
                        filepath = os.path.join(BLOG_UPLOAD_FOLDER, filename)
                        img.save(filepath)
                        
                        # Save to database
                        cur.execute("""
                            INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
                            VALUES (%s, 'image', %s, %s)
                        """, (blog_id, f'img/blogs/{filename}', image_count))
                        
                        image_count += 1
            
            # Handle video (up to 1)
            video = request.files.get('video')
            if video and video.filename:
                if allowed_file(video.filename, 'video'):
                    filename = secure_filename(f"blog_{blog_id}_video_{datetime.now().strftime('%Y%m%d%H%M%S')}_{video.filename}")
                    filepath = os.path.join(BLOG_UPLOAD_FOLDER, filename)
                    video.save(filepath)
                    
                    # Save to database
                    cur.execute("""
                        INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
                        VALUES (%s, 'video', %s, %s)
                    """, (blog_id, f'img/blogs/{filename}', 2))
            
            conn.commit()
            cur.close()
            conn.close()
            
            flash('Blog submitted successfully! It will be visible after admin approval.', 'success')
            return redirect(url_for('my_blogs'))
            
        except Exception as e:
            print(f"Error creating blog: {e}")
            conn.rollback()
            flash('Error creating blog', 'error')
            return redirect(url_for('create_blog'))
    
    # -----------------------
    # MY BLOGS
    # -----------------------
    @app.route('/my-blogs')
    @login_required
    def my_blogs():
        """Display current user's blogs"""
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('index'))
        
        try:
            cur = conn.cursor()
            
            cur.execute("""
                SELECT
                    cb.id, cb.title, cb.status, cb.views, cb.created_at,
                    COUNT(DISTINCT br.id) as reaction_count,
                    COUNT(DISTINCT bc.id) as comment_count,
                    (SELECT media_url FROM blog_media WHERE blog_id = cb.id AND media_type = 'image' ORDER BY media_order LIMIT 1) as thumbnail
                FROM customer_blogs cb
                LEFT JOIN blog_reactions br ON cb.id = br.blog_id
                LEFT JOIN blog_comments bc ON cb.id = bc.blog_id
                WHERE cb.user_id = %s
                GROUP BY cb.id
                ORDER BY cb.created_at DESC
            """, (current_user.id,))
            
            blogs = cur.fetchall()
            
            cur.close()
            conn.close()
            
            return render_template('my_blogs.html', blogs=blogs)
            
        except Exception as e:
            print(f"Error fetching user blogs: {e}")
    
    # -----------------------
    # EDIT BLOG
    # -----------------------
    @app.route('/blog/<int:blog_id>/edit', methods=['GET', 'POST'])
    @login_required
    def edit_blog(blog_id):
        """Edit user's own blog"""
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('my_blogs'))
        
        try:
            cur = conn.cursor()
            
            # Get blog and verify ownership
            cur.execute("""
                SELECT id, user_id, title, content, status
                FROM customer_blogs
                WHERE id = %s
            """, (blog_id,))
            
            blog = cur.fetchone()
            
            if not blog:
                flash('Blog not found', 'error')
                return redirect(url_for('my_blogs'))
            
            # Check if user owns this blog
            if blog[1] != current_user.id:
                flash('You can only edit your own blogs', 'error')
                return redirect(url_for('my_blogs'))
            
            # Check if blog is approved (can't edit approved blogs)
            if blog[4] == 'approved':
                flash('Cannot edit approved blogs. Please contact admin if you need changes.', 'warning')
                return redirect(url_for('my_blogs'))
            
            if request.method == 'GET':
                # Get existing media
                cur.execute("""
                    SELECT id, media_type, media_url, media_order
                    FROM blog_media
                    WHERE blog_id = %s
                    ORDER BY media_order
                """, (blog_id,))
                media = cur.fetchall()
                
                cur.close()
                conn.close()
                
                return render_template('edit_blog.html', blog=blog, media=media)
            
            # POST request - handle blog update
            title = request.form.get('title', '').strip()
            content = request.form.get('content', '').strip()
            
            if not title or not content:
                flash('Title and content are required', 'error')
                return redirect(url_for('edit_blog', blog_id=blog_id))
            
            if len(title) > 255:
                flash('Title is too long (max 255 characters)', 'error')
                return redirect(url_for('edit_blog', blog_id=blog_id))
            
            # Sanitize HTML content
            content = sanitize_html(content)
            
            # Update blog
            cur.execute("""
                UPDATE customer_blogs 
                SET title = %s, content = %s, status = 'pending', updated_at = CURRENT_TIMESTAMP
                WHERE id = %s AND user_id = %s
            """, (title, content, blog_id, current_user.id))
            
            # Handle new file uploads if provided
            images = request.files.getlist('images')
            if images and images[0].filename:
                # Get current image count
                cur.execute("""
                    SELECT COUNT(*) FROM blog_media 
                    WHERE blog_id = %s AND media_type = 'image'
                """, (blog_id,))
                current_image_count = cur.fetchone()[0]
                
                image_count = current_image_count
                for img in images:
                    if img and img.filename and image_count < 2:
                        if allowed_file(img.filename, 'image'):
                            filename = secure_filename(f"blog_{blog_id}_{image_count}_{datetime.now().strftime('%Y%m%d%H%M%S')}_{img.filename}")
                            filepath = os.path.join(BLOG_UPLOAD_FOLDER, filename)
                            img.save(filepath)
                            
                            cur.execute("""
                                INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
                                VALUES (%s, 'image', %s, %s)
                            """, (blog_id, f'img/blogs/{filename}', image_count))
                            
                            image_count += 1
            
            # Handle new video if provided
            video = request.files.get('video')
            if video and video.filename:
                if allowed_file(video.filename, 'video'):
                    # Check if video already exists
                    cur.execute("""
                        SELECT COUNT(*) FROM blog_media 
                        WHERE blog_id = %s AND media_type = 'video'
                    """, (blog_id,))
                    
                    if cur.fetchone()[0] == 0:
                        filename = secure_filename(f"blog_{blog_id}_video_{datetime.now().strftime('%Y%m%d%H%M%S')}_{video.filename}")
                        filepath = os.path.join(BLOG_UPLOAD_FOLDER, filename)
                        video.save(filepath)
                        
                        cur.execute("""
                            INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
                            VALUES (%s, 'video', %s, %s)
                        """, (blog_id, f'img/blogs/{filename}', 2))
            
            conn.commit()
            cur.close()
            conn.close()
            
            flash('Blog updated successfully! It will be reviewed again by admin.', 'success')
            return redirect(url_for('my_blogs'))
            
        except Exception as e:
            print(f"Error updating blog: {e}")
            conn.rollback()
            flash('Error updating blog', 'error')
            return redirect(url_for('edit_blog', blog_id=blog_id))
    
    # -----------------------
    # DELETE BLOG MEDIA
    # -----------------------
    @app.route('/blog/<int:blog_id>/media/<int:media_id>/delete', methods=['POST'])
    @login_required
    def delete_blog_media(blog_id, media_id):
        """Delete a media file from user's blog"""
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database error'})
        
        try:
            cur = conn.cursor()
            
            # Verify blog ownership
            cur.execute("""
                SELECT user_id FROM customer_blogs WHERE id = %s
            """, (blog_id,))
            
            blog = cur.fetchone()
            if not blog or blog[0] != current_user.id:
                return jsonify({'success': False, 'message': 'Unauthorized'})
            
            # Get media file path
            cur.execute("""
                SELECT media_url FROM blog_media WHERE id = %s AND blog_id = %s
            """, (media_id, blog_id))
            
            media = cur.fetchone()
            if not media:
                return jsonify({'success': False, 'message': 'Media not found'})
            
            # Delete from database
            cur.execute("""
                DELETE FROM blog_media WHERE id = %s AND blog_id = %s
            """, (media_id, blog_id))
            
            conn.commit()
            cur.close()
            conn.close()
            
            # Delete physical file
            try:
                filepath = os.path.join('static', media[0])
                if os.path.exists(filepath):
                    os.remove(filepath)
            except Exception as e:
                print(f"Error deleting file: {e}")
            
            return jsonify({'success': True, 'message': 'Media deleted'})
            
        except Exception as e:
            print(f"Error deleting media: {e}")
            return jsonify({'success': False, 'message': 'Error deleting media'})
            flash('Error loading your blogs', 'error')
            return redirect(url_for('index'))
    
    # -----------------------
    # REACT TO BLOG (with emoji reactions)
    # -----------------------
    @app.route('/blog/<int:blog_id>/react', methods=['POST'])
    def react_to_blog(blog_id):
        """Add or remove emoji reaction to a blog (works for logged in and guest users)"""
        data = request.get_json()
        reaction_type = data.get('reaction_type')
        
        # Validate reaction type
        valid_reactions = ['love', 'fire', 'happy', 'wow', 'clap', 'heart']
        if reaction_type not in valid_reactions:
            return jsonify({'success': False, 'message': 'Invalid reaction type'})
        
        # Get or create session ID for guest users
        if not session.get('session_id'):
            session['session_id'] = str(uuid.uuid4())
        
        session_id = session.get('session_id')
        user_id = current_user.id if current_user.is_authenticated else None
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database error'})
        
        try:
            cur = conn.cursor()
            
            # Check if user/session already reacted with this type
            if user_id:
                cur.execute("""
                    SELECT id FROM blog_reactions
                    WHERE blog_id = %s AND user_id = %s AND reaction_type = %s
                """, (blog_id, user_id, reaction_type))
            else:
                cur.execute("""
                    SELECT id FROM blog_reactions
                    WHERE blog_id = %s AND session_id = %s AND reaction_type = %s
                """, (blog_id, session_id, reaction_type))
            
            existing_reaction = cur.fetchone()
            
            if existing_reaction:
                # Remove reaction
                if user_id:
                    cur.execute("""
                        DELETE FROM blog_reactions
                        WHERE blog_id = %s AND user_id = %s AND reaction_type = %s
                    """, (blog_id, user_id, reaction_type))
                else:
                    cur.execute("""
                        DELETE FROM blog_reactions
                        WHERE blog_id = %s AND session_id = %s AND reaction_type = %s
                    """, (blog_id, session_id, reaction_type))
                action = 'removed'
            else:
                # Add reaction
                if user_id:
                    cur.execute("""
                        INSERT INTO blog_reactions (blog_id, user_id, reaction_type)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (blog_id, user_id, reaction_type) DO NOTHING
                    """, (blog_id, user_id, reaction_type))
                else:
                    cur.execute("""
                        INSERT INTO blog_reactions (blog_id, session_id, reaction_type)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (blog_id, session_id, reaction_type) DO NOTHING
                    """, (blog_id, session_id, reaction_type))
                action = 'added'
            
            conn.commit()
            
            # Get updated reaction counts
            cur.execute("""
                SELECT reaction_type, COUNT(*) as count
                FROM blog_reactions
                WHERE blog_id = %s
                GROUP BY reaction_type
            """, (blog_id,))
            reactions = {row[0]: row[1] for row in cur.fetchall()}
            
            cur.close()
            conn.close()
            
            return jsonify({
                'success': True,
                'action': action,
                'reactions': reactions
            })
            
        except Exception as e:
            print(f"Error processing reaction: {e}")
            return jsonify({'success': False, 'message': 'Error processing reaction'})
    
    # -----------------------
    # ADD COMMENT
    # -----------------------
    @app.route('/blog/<int:blog_id>/comment', methods=['POST'])
    @login_required
    def add_comment(blog_id):
        """Add a comment to a blog"""
        comment = request.form.get('comment', '').strip()
        
        if not comment:
            flash('Comment cannot be empty', 'error')
            return redirect(url_for('blog_detail', blog_id=blog_id))
        
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('blog_detail', blog_id=blog_id))
        
        try:
            cur = conn.cursor()
            
            cur.execute("""
                INSERT INTO blog_comments (blog_id, user_id, comment)
                VALUES (%s, %s, %s)
            """, (blog_id, current_user.id, comment))
            
            conn.commit()
            cur.close()
            conn.close()
            
            flash('Comment added successfully', 'success')
            return redirect(url_for('blog_detail', blog_id=blog_id))
            
        except Exception as e:
            print(f"Error adding comment: {e}")
            flash('Error adding comment', 'error')
            return redirect(url_for('blog_detail', blog_id=blog_id))
    
    # -----------------------
    # ADMIN: MANAGE BLOGS
    # -----------------------
    @app.route('/admin/blogs')
    @login_required
    def admin_blogs():
        """Admin page to manage all blogs"""
        if not current_user.is_admin:
            flash('Unauthorized access', 'error')
            return redirect(url_for('index'))
        
        conn = connect_to_db()
        if not conn:
            flash('Database connection error', 'error')
            return redirect(url_for('index'))
        
        try:
            cur = conn.cursor()
            
            status_filter = request.args.get('status', 'all')
            
            if status_filter == 'all':
                status_clause = ""
            else:
                status_clause = f"WHERE cb.status = '{status_filter}'"
            
            cur.execute(f"""
                SELECT
                    cb.id, cb.title, cb.status, cb.views, cb.created_at,
                    u.name as author_name, u.email as author_email,
                    COUNT(DISTINCT br.id) as reaction_count,
                    COUNT(DISTINCT bc.id) as comment_count
                FROM customer_blogs cb
                JOIN users u ON cb.user_id = u.id
                LEFT JOIN blog_reactions br ON cb.id = br.blog_id
                LEFT JOIN blog_comments bc ON cb.id = bc.blog_id
                {status_clause}
                GROUP BY cb.id, u.name, u.email
                ORDER BY cb.created_at DESC
            """)
            
            blogs = cur.fetchall()
            
            cur.close()
            conn.close()
            
            return render_template('admin_blogs.html', blogs=blogs, status_filter=status_filter)
            
        except Exception as e:
            print(f"Error fetching admin blogs: {e}")
            flash('Error loading blogs', 'error')
            return redirect(url_for('index'))
    
    # -----------------------
    # ADMIN: APPROVE BLOG
    # -----------------------
    @app.route('/admin/blogs/<int:blog_id>/approve', methods=['POST'])
    @login_required
    def approve_blog(blog_id):
        """Approve a blog"""
        if not current_user.is_admin:
            return jsonify({'success': False, 'message': 'Unauthorized'})
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database error'})
        
        try:
            cur = conn.cursor()
            
            cur.execute("""
                UPDATE customer_blogs 
                SET status = 'approved', approved_at = CURRENT_TIMESTAMP, approved_by = %s
                WHERE id = %s
            """, (current_user.id, blog_id))
            
            conn.commit()
            cur.close()
            conn.close()
            
            return jsonify({'success': True, 'message': 'Blog approved'})
            
        except Exception as e:
            print(f"Error approving blog: {e}")
            return jsonify({'success': False, 'message': 'Error approving blog'})
    
    # -----------------------
    # ADMIN: REJECT BLOG
    # -----------------------
    @app.route('/admin/blogs/<int:blog_id>/reject', methods=['POST'])
    @login_required
    def reject_blog(blog_id):
        """Reject a blog"""
        if not current_user.is_admin:
            return jsonify({'success': False, 'message': 'Unauthorized'})
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database error'})
        
        try:
            cur = conn.cursor()
            
            cur.execute("""
                UPDATE customer_blogs 
                SET status = 'rejected'
                WHERE id = %s
            """, (blog_id,))
            
            conn.commit()
            cur.close()
            conn.close()
            
            return jsonify({'success': True, 'message': 'Blog rejected'})
            
        except Exception as e:
            print(f"Error rejecting blog: {e}")
            return jsonify({'success': False, 'message': 'Error rejecting blog'})
    
    # -----------------------
    # ADMIN: DELETE BLOG
    # -----------------------
    @app.route('/admin/blogs/<int:blog_id>/delete', methods=['POST'])
    @login_required
    def delete_blog(blog_id):
        """Delete a blog"""
        if not current_user.is_admin:
            return jsonify({'success': False, 'message': 'Unauthorized'})
        
        conn = connect_to_db()
        if not conn:
            return jsonify({'success': False, 'message': 'Database error'})
        
        try:
            cur = conn.cursor()
            
            # Get media files to delete
            cur.execute("""
                SELECT media_url FROM blog_media WHERE blog_id = %s
            """, (blog_id,))
            media_files = cur.fetchall()
            
            # Delete blog (cascade will delete media records, likes, comments)
            cur.execute("DELETE FROM customer_blogs WHERE id = %s", (blog_id,))
            
            conn.commit()
            cur.close()
            conn.close()
            
            # Delete physical files
            for media in media_files:
                try:
                    filepath = os.path.join('static', media[0])
                    if os.path.exists(filepath):
                        os.remove(filepath)
                except Exception as e:
                    print(f"Error deleting file {media[0]}: {e}")
            
            return jsonify({'success': True, 'message': 'Blog deleted'})
            
        except Exception as e:
            print(f"Error deleting blog: {e}")
            return jsonify({'success': False, 'message': 'Error deleting blog'})

# Made with Bob
