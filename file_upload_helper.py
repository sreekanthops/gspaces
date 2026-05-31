"""
File Upload Helper
Provides centralized file naming conventions for all uploads across the application
"""
import os
from datetime import datetime
from werkzeug.utils import secure_filename

def get_file_extension(filename):
    """Extract file extension from filename"""
    return os.path.splitext(filename)[1].lower()

def generate_upload_filename(category, identifier, counter=None, original_filename=None):
    """
    Generate standardized filename for uploads
    
    Args:
        category: Upload category (e.g., 'product', 'lead_ref', 'lead_design', 'blog', 'profile', 'icon')
        identifier: Unique identifier (e.g., product_id, lead_id, user_id, item_name)
        counter: Optional counter for multiple files (1, 2, 3, etc.)
        original_filename: Original uploaded filename (to extract extension)
    
    Returns:
        Formatted filename with timestamp and extension
    
    Examples:
        product_123_1_20260531_143022.jpg
        lead_ref_45_20260531_143022.png
        lead_design_whitewash_1_20260531_143022.mp4
        blog_10_2_20260531_143022.jpg
        profile_user_14_20260531_143022.png
        icon_desk_lamp_20260531_143022.png
    """
    # Get timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # Get file extension
    if original_filename:
        ext = get_file_extension(original_filename)
    else:
        ext = ''
    
    # Build filename parts
    parts = [category, str(identifier)]
    
    # Add counter if provided
    if counter is not None:
        parts.append(str(counter))
    
    # Add timestamp
    parts.append(timestamp)
    
    # Join parts and add extension
    filename = '_'.join(parts) + ext
    
    return filename

def generate_lead_reference_filename(lead_id, original_filename):
    """Generate filename for lead reference image"""
    return generate_upload_filename('lead_ref', lead_id, original_filename=original_filename)

def generate_lead_design_filename(design_name, counter, original_filename):
    """Generate filename for lead design media"""
    # Sanitize design name for filename
    safe_name = secure_filename(design_name.lower().replace(' ', '_'))
    return generate_upload_filename('lead_design', safe_name, counter, original_filename)

def generate_lead_media_filename(lead_id, design_name, counter, original_filename):
    """Generate filename for lead media files"""
    safe_name = secure_filename(design_name.lower().replace(' ', '_'))
    return generate_upload_filename(f'lead_media_{lead_id}', safe_name, counter, original_filename)

def generate_product_filename(product_id, counter, original_filename):
    """Generate filename for product images"""
    return generate_upload_filename('product', product_id, counter, original_filename)

def generate_blog_filename(blog_id, counter, original_filename):
    """Generate filename for blog media"""
    return generate_upload_filename('blog', blog_id, counter, original_filename)

def generate_profile_filename(user_id, original_filename):
    """Generate filename for user profile photo"""
    return generate_upload_filename('profile_user', user_id, original_filename=original_filename)

def generate_icon_filename(item_name, original_filename):
    """Generate filename for default item icons"""
    safe_name = secure_filename(item_name.lower().replace(' ', '_'))
    return generate_upload_filename('icon', safe_name, original_filename=original_filename)

def generate_review_filename(product_id, review_id, counter, original_filename):
    """Generate filename for review media"""
    return generate_upload_filename(f'review_{product_id}', review_id, counter, original_filename)

def generate_inquiry_filename(inquiry_id, counter, original_filename):
    """Generate filename for customer inquiry files"""
    return generate_upload_filename('inquiry', inquiry_id, counter, original_filename)

def generate_banner_filename(banner_id, original_filename):
    """Generate filename for homepage banner/carousel images"""
    return generate_upload_filename('banner', banner_id, original_filename=original_filename)

def generate_design_gallery_filename(design_id, counter, original_filename):
    """Generate filename for design gallery images"""
    return generate_upload_filename('gallery_design', design_id, counter, original_filename)

def generate_furniture_filename(furniture_id, original_filename):
    """Generate filename for AI furniture visualization"""
    return generate_upload_filename('furniture', furniture_id, original_filename=original_filename)

# Backward compatibility - keep old function names but use new system
def get_timestamped_filename(prefix, original_filename):
    """Legacy function - generates timestamped filename"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    ext = get_file_extension(original_filename)
    return f"{prefix}_{timestamp}{ext}"

# Made with Bob
