"""
Performance optimization configuration for Flask app
Implements caching, compression, and other performance improvements
"""

from flask import Flask, make_response, request, send_from_directory
from functools import wraps
from datetime import datetime, timedelta
import hashlib

def add_performance_headers(app):
    """Add performance-related headers to all responses"""
    
    @app.after_request
    def set_response_headers(response):
        # Don't cache dynamic content
        if request.endpoint and 'static' not in request.endpoint:
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
        
        # Security headers
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'SAMEORIGIN'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        
        return response
    
    @app.route('/static/<path:filename>')
    def static_with_cache(filename):
        """Serve static files with long cache times"""
        response = make_response(send_from_directory('static', filename))
        
        # Cache static assets for 1 year
        response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
        
        # Add ETag for cache validation
        if filename:
            etag = hashlib.md5(filename.encode()).hexdigest()
            response.headers['ETag'] = etag
        
        return response

def enable_compression(app):
    """Enable gzip compression for responses"""
    try:
        from flask_compress import Compress
        Compress(app)
        app.config['COMPRESS_MIMETYPES'] = [
            'text/html',
            'text/css',
            'text/xml',
            'application/json',
            'application/javascript',
            'text/javascript',
            'image/svg+xml'
        ]
        app.config['COMPRESS_LEVEL'] = 6
        app.config['COMPRESS_MIN_SIZE'] = 500
        return True
    except ImportError:
        print("Warning: flask-compress not installed. Run: pip install flask-compress")
        return False

def configure_performance(app):
    """Configure all performance optimizations"""
    
    # Enable compression
    enable_compression(app)
    
    # Add performance headers
    add_performance_headers(app)
    
    # Configure session
    app.config['SESSION_COOKIE_SECURE'] = True
    app.config['SESSION_COOKIE_HTTPONLY'] = True
    app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
    
    # Configure permanent session lifetime
    app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=7)
    
    print("✓ Performance optimizations configured")
    return app

# Made with Bob
