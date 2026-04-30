#!/usr/bin/env python3
"""
CSS minification script for GSpaces
"""

import re
import os

def minify_css(css_content):
    """Minify CSS content"""
    # Remove comments
    css_content = re.sub(r'/\*.*?\*/', '', css_content, flags=re.DOTALL)
    # Remove whitespace
    css_content = re.sub(r'\s+', ' ', css_content)
    # Remove spaces around special characters
    css_content = re.sub(r'\s*([{}:;,>+~])\s*', r'\1', css_content)
    # Remove trailing semicolons
    css_content = re.sub(r';}', '}', css_content)
    return css_content.strip()

def minify_css_file(input_file, output_file=None):
    """Minify a CSS file"""
    if output_file is None:
        output_file = input_file.replace('.css', '.min.css')
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            css_content = f.read()
        
        minified = minify_css(css_content)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(minified)
        
        original_size = len(css_content)
        minified_size = len(minified)
        saved = original_size - minified_size
        
        print(f"✓ {input_file} -> {output_file}")
        print(f"  Saved {saved/1024:.1f} KB ({saved*100/original_size:.1f}%)")
        
    except Exception as e:
        print(f"✗ Error minifying {input_file}: {e}")

if __name__ == '__main__':
    css_file = 'static/css/main.css'
    if os.path.exists(css_file):
        print(f"Minifying {css_file}...")
        minify_css_file(css_file)
    else:
        print(f"Warning: {css_file} not found")
