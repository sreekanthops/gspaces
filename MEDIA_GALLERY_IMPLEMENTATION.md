# Lead Design Media Gallery - Implementation Guide

## Overview
Add media gallery feature to lead designs allowing admins to upload up to 5 media files (max 2 videos, max 3 images) with auto carousel, navigation buttons, and full-screen lightbox view.

## Requirements
- **Images**: Max 3, 5MB each (PNG, JPG, JPEG, GIF, WEBP)
- **Videos**: Max 2, 50MB each (MP4, WEBM, MOV)
- **Total**: Max 5 files combined
- **Features**: Auto carousel, left/right navigation, full-screen lightbox

## Database Schema

### Table: lead_designs
```sql
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS media_files JSONB DEFAULT '[]'::jsonb;
```

### Data Structure
```json
[
  {
    "type": "image",
    "url": "img/leads/media/design_123_1_20260503_143000.jpg",
    "order": 1,
    "size": 2048000,
    "filename": "room_view.jpg"
  },
  {
    "type": "video",
    "url": "img/leads/media/design_123_2_20260503_143100.mp4",
    "order": 2,
    "size": 15360000,
    "filename": "walkthrough.mp4"
  }
]
```

## Backend Implementation

### 1. File Upload Route (leads_simple.py)

```python
@leads_bp.route('/admin/design/<int:design_id>/upload-media', methods=['POST'])
@admin_required
def upload_design_media(design_id):
    """Upload media files to design gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get current media files
        cur.execute("SELECT media_files FROM lead_designs WHERE id = %s", (design_id,))
        result = cur.fetchone()
        media_files = result['media_files'] if result and result['media_files'] else []
        
        # Count current files
        image_count = sum(1 for m in media_files if m['type'] == 'image')
        video_count = sum(1 for m in media_files if m['type'] == 'video')
        
        # Process uploaded files
        files = request.files.getlist('media_files')
        
        for file in files:
            if not file or not file.filename:
                continue
                
            # Validate file type
            ext = file.filename.rsplit('.', 1)[1].lower()
            is_image = ext in ['png', 'jpg', 'jpeg', 'gif', 'webp']
            is_video = ext in ['mp4', 'webm', 'mov']
            
            if not (is_image or is_video):
                flash(f'Invalid file type: {file.filename}', 'danger')
                continue
            
            # Check limits
            if is_image and image_count >= 3:
                flash('Maximum 3 images allowed', 'warning')
                continue
            if is_video and video_count >= 2:
                flash('Maximum 2 videos allowed', 'warning')
                continue
            if len(media_files) >= 5:
                flash('Maximum 5 files allowed', 'warning')
                break
            
            # Check file size
            file.seek(0, 2)  # Seek to end
            file_size = file.tell()
            file.seek(0)  # Reset
            
            max_size = 5 * 1024 * 1024 if is_image else 50 * 1024 * 1024
            if file_size > max_size:
                size_mb = max_size / (1024 * 1024)
                flash(f'{file.filename} exceeds {size_mb}MB limit', 'danger')
                continue
            
            # Save file
            filename = secure_filename(file.filename)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            order = len(media_files) + 1
            filename = f"design_{design_id}_{order}_{timestamp}_{filename}"
            
            media_folder = os.path.join('static', 'img', 'leads', 'media')
            os.makedirs(media_folder, exist_ok=True)
            filepath = os.path.join(media_folder, filename)
            file.save(filepath)
            
            # Add to media_files
            media_files.append({
                'type': 'image' if is_image else 'video',
                'url': f"img/leads/media/{filename}",
                'order': order,
                'size': file_size,
                'filename': file.filename
            })
            
            if is_image:
                image_count += 1
            else:
                video_count += 1
        
        # Update database
        cur.execute("""
            UPDATE lead_designs 
            SET media_files = %s 
            WHERE id = %s
        """, (json.dumps(media_files), design_id))
        
        conn.commit()
        flash('Media files uploaded successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error uploading media: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=request.args.get('lead_id')))

@leads_bp.route('/admin/design/<int:design_id>/delete-media/<int:media_index>', methods=['POST'])
@admin_required
def delete_design_media(design_id, media_index):
    """Delete a media file from design gallery"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get current media files
        cur.execute("SELECT media_files FROM lead_designs WHERE id = %s", (design_id,))
        result = cur.fetchone()
        media_files = result['media_files'] if result and result['media_files'] else []
        
        if 0 <= media_index < len(media_files):
            # Delete file from filesystem
            file_path = os.path.join('static', media_files[media_index]['url'])
            if os.path.exists(file_path):
                os.remove(file_path)
            
            # Remove from array
            media_files.pop(media_index)
            
            # Reorder remaining files
            for i, media in enumerate(media_files):
                media['order'] = i + 1
            
            # Update database
            cur.execute("""
                UPDATE lead_designs 
                SET media_files = %s 
                WHERE id = %s
            """, (json.dumps(media_files), design_id))
            
            conn.commit()
            flash('Media file deleted successfully!', 'success')
        
    except Exception as e:
        conn.rollback()
        flash(f'Error deleting media: {str(e)}', 'danger')
    finally:
        cur.close()
        conn.close()
    
    return redirect(url_for('leads.edit_lead', lead_id=request.args.get('lead_id')))
```

## Frontend Implementation

### 1. Media Upload Section (edit_lead_simple.html)

Add after design image upload section:

```html
<!-- Media Gallery Section -->
<div class="mb-4 p-3" style="background: #f0f9ff; border-radius: 10px; border: 2px solid #3b82f6;">
    <h6 class="mb-3"><i class="bi bi-images"></i> Media Gallery (Max 5: 3 images + 2 videos)</h6>
    
    <!-- Current Media Files -->
    {% if design.media_files %}
    <div class="row mb-3">
        {% for media in design.media_files %}
        <div class="col-md-4 mb-3">
            <div class="card">
                {% if media.type == 'image' %}
                    <img src="{{ url_for('static', filename=media.url) }}" 
                         class="card-img-top" alt="Design media"
                         style="height: 150px; object-fit: cover; cursor: pointer;"
                         onclick="openLightbox({{ loop.index0 }})">
                {% else %}
                    <video class="card-img-top" style="height: 150px; object-fit: cover;">
                        <source src="{{ url_for('static', filename=media.url) }}" type="video/mp4">
                    </video>
                {% endif %}
                <div class="card-body p-2">
                    <small class="text-muted">{{ media.filename }}</small>
                    <form method="POST" 
                          action="{{ url_for('leads.delete_design_media', design_id=design.id, media_index=loop.index0) }}?lead_id={{ lead.id }}"
                          style="display: inline;">
                        <button type="submit" class="btn btn-sm btn-danger float-end"
                                onclick="return confirm('Delete this media file?')">
                            <i class="bi bi-trash"></i>
                        </button>
                    </form>
                </div>
            </div>
        </div>
        {% endfor %}
    </div>
    {% endif %}
    
    <!-- Upload Form -->
    <form method="POST" enctype="multipart/form-data"
          action="{{ url_for('leads.upload_design_media', design_id=design.id) }}?lead_id={{ lead.id }}">
        <div class="mb-3">
            <label class="form-label">Upload Media Files</label>
            <input type="file" name="media_files" class="form-control" multiple
                   accept="image/*,video/mp4,video/webm,video/mov"
                   onchange="validateMediaFiles(this)">
            <small class="text-muted">
                Images: PNG, JPG (max 5MB each) | Videos: MP4, WEBM (max 50MB each)
            </small>
        </div>
        <button type="submit" class="btn btn-primary btn-sm">
            <i class="bi bi-upload"></i> Upload Media
        </button>
    </form>
</div>
```

### 2. Lightbox Modal (edit_lead_simple.html)

Add before closing `</body>` tag:

```html
<!-- Lightbox Modal -->
<div class="modal fade" id="mediaLightbox" tabindex="-1">
    <div class="modal-dialog modal-fullscreen">
        <div class="modal-content bg-dark">
            <div class="modal-header border-0">
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body d-flex align-items-center justify-content-center position-relative">
                <!-- Previous Button -->
                <button class="btn btn-light position-absolute start-0 ms-3" 
                        onclick="navigateMedia(-1)" style="z-index: 1000;">
                    <i class="bi bi-chevron-left"></i>
                </button>
                
                <!-- Media Container -->
                <div id="lightboxContent" class="text-center" style="max-width: 90%; max-height: 90vh;">
                    <!-- Content injected by JavaScript -->
                </div>
                
                <!-- Next Button -->
                <button class="btn btn-light position-absolute end-0 me-3" 
                        onclick="navigateMedia(1)" style="z-index: 1000;">
                    <i class="bi bi-chevron-right"></i>
                </button>
            </div>
            <div class="modal-footer border-0 justify-content-center">
                <span id="mediaCounter" class="text-white"></span>
            </div>
        </div>
    </div>
</div>
```

### 3. JavaScript Functions (edit_lead_simple.html)

Add in `<script>` section:

```javascript
// Media Gallery Variables
let currentMediaIndex = 0;
let mediaFiles = {{ design.media_files|tojson if design.media_files else '[]'|safe }};

// Validate file uploads
function validateMediaFiles(input) {
    const files = input.files;
    let imageCount = 0;
    let videoCount = 0;
    
    for (let file of files) {
        const ext = file.name.split('.').pop().toLowerCase();
        const isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].includes(ext);
        const isVideo = ['mp4', 'webm', 'mov'].includes(ext);
        
        if (isImage) {
            imageCount++;
            if (file.size > 5 * 1024 * 1024) {
                alert(`${file.name} exceeds 5MB limit for images`);
                input.value = '';
                return false;
            }
        } else if (isVideo) {
            videoCount++;
            if (file.size > 50 * 1024 * 1024) {
                alert(`${file.name} exceeds 50MB limit for videos`);
                input.value = '';
                return false;
            }
        }
    }
    
    if (imageCount > 3) {
        alert('Maximum 3 images allowed');
        input.value = '';
        return false;
    }
    if (videoCount > 2) {
        alert('Maximum 2 videos allowed');
        input.value = '';
        return false;
    }
    if (files.length > 5) {
        alert('Maximum 5 files allowed');
        input.value = '';
        return false;
    }
    
    return true;
}

// Open lightbox
function openLightbox(index) {
    currentMediaIndex = index;
    showMedia(index);
    new bootstrap.Modal(document.getElementById('mediaLightbox')).show();
}

// Show media in lightbox
function showMedia(index) {
    if (index < 0 || index >= mediaFiles.length) return;
    
    const media = mediaFiles[index];
    const content = document.getElementById('lightboxContent');
    const counter = document.getElementById('mediaCounter');
    
    if (media.type === 'image') {
        content.innerHTML = `<img src="/static/${media.url}" style="max-width: 100%; max-height: 90vh; object-fit: contain;">`;
    } else {
        content.innerHTML = `
            <video controls autoplay style="max-width: 100%; max-height: 90vh;">
                <source src="/static/${media.url}" type="video/mp4">
            </video>
        `;
    }
    
    counter.textContent = `${index + 1} / ${mediaFiles.length}`;
}

// Navigate media
function navigateMedia(direction) {
    currentMediaIndex += direction;
    if (currentMediaIndex < 0) currentMediaIndex = mediaFiles.length - 1;
    if (currentMediaIndex >= mediaFiles.length) currentMediaIndex = 0;
    showMedia(currentMediaIndex);
}

// Auto carousel (optional)
let carouselInterval;
function startCarousel() {
    carouselInterval = setInterval(() => {
        navigateMedia(1);
    }, 5000); // Change every 5 seconds
}

function stopCarousel() {
    clearInterval(carouselInterval);
}

// Keyboard navigation
document.addEventListener('keydown', (e) => {
    const modal = document.getElementById('mediaLightbox');
    if (modal.classList.contains('show')) {
        if (e.key === 'ArrowLeft') navigateMedia(-1);
        if (e.key === 'ArrowRight') navigateMedia(1);
        if (e.key === 'Escape') bootstrap.Modal.getInstance(modal).hide();
    }
});
```

## Deployment Steps

1. **Run SQL Migration**
```bash
psql -U sri -d gspaces < create_lead_design_media_gallery.sql
```

2. **Update leads_simple.py**
- Add upload_design_media route
- Add delete_design_media route

3. **Update edit_lead_simple.html**
- Add media gallery section
- Add lightbox modal
- Add JavaScript functions

4. **Create media directory**
```bash
mkdir -p static/img/leads/media
chmod 755 static/img/leads/media
```

5. **Test**
- Upload images (max 3, 5MB each)
- Upload videos (max 2, 50MB each)
- Test carousel navigation
- Test full-screen lightbox
- Test delete functionality

## Features Checklist

- [ ] Upload validation (file types, sizes, counts)
- [ ] Media gallery display in edit page
- [ ] Delete individual media files
- [ ] Full-screen lightbox view
- [ ] Left/Right navigation buttons
- [ ] Keyboard navigation (arrow keys, ESC)
- [ ] Auto carousel (optional, 5s interval)
- [ ] Media counter (1/5, 2/5, etc.)
- [ ] Responsive design
- [ ] Video playback controls

## Made with Bob 🤖