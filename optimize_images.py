#!/usr/bin/env python3
"""
Image optimization script for GSpaces
Compresses and optimizes images to reduce file size
"""

import os
from PIL import Image
import sys

def optimize_image(image_path, quality=85):
    """Optimize a single image"""
    try:
        img = Image.open(image_path)
        
        # Convert RGBA to RGB if necessary
        if img.mode == 'RGBA':
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3])
            img = background
        
        # Get original size
        original_size = os.path.getsize(image_path)
        
        # Save optimized image
        img.save(image_path, optimize=True, quality=quality)
        
        # Get new size
        new_size = os.path.getsize(image_path)
        saved = original_size - new_size
        
        if saved > 0:
            print(f"✓ {image_path}: Saved {saved/1024:.1f} KB ({saved*100/original_size:.1f}%)")
            return saved
        else:
            print(f"- {image_path}: Already optimized")
            return 0
            
    except Exception as e:
        print(f"✗ Error optimizing {image_path}: {e}")
        return 0

def optimize_directory(directory, extensions=['.jpg', '.jpeg', '.png']):
    """Optimize all images in a directory"""
    total_saved = 0
    count = 0
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if any(file.lower().endswith(ext) for ext in extensions):
                image_path = os.path.join(root, file)
                saved = optimize_image(image_path)
                total_saved += saved
                count += 1
    
    print(f"\nTotal: Optimized {count} images, saved {total_saved/1024:.1f} KB")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        directory = 'static/img'
    
    print(f"Optimizing images in {directory}...")
    optimize_directory(directory)
