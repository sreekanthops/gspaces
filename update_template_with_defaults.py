#!/usr/bin/env python3
"""
Script to update edit_lead_simple.html to use default prices from database
This fixes the issue where prices show as 0 or empty string instead of default values
"""

import re

# Read the template
with open('templates/edit_lead_simple.html', 'r') as f:
    content = f.read()

# Define all items that need default prices
items = [
    'table', 'chair', 'lighting', 'storage', 'accessories',
    'big_plants', 'mini_plants', 'frames', 'wall_racks', 'desk_mat',
    'dustbin', 'floor_mat', 'keyboard', 'mouse', 'paint', 'wardrobes',
    'carpet', 'curtains', 'wall_art', 'desk_organizer', 'monitor_stand',
    'cable_management', 'footrest', 'monitor', 'laptop_stand',
    'headphone_stand', 'whiteboard', 'bookshelf', 'trash_bin',
    'desk_lamp', 'pen_holder', 'laptop_holder'
]

# Replace all price field patterns
for item in items:
    # Pattern 1: or '' (empty string)
    pattern1 = rf'(name="{item}_price"[^>]*value="{{\{{ design\.{item}_price) or \'\' (}}\}}")'
    replacement1 = rf'\1 or default_prices.get("{item}", 0) \2'
    content = re.sub(pattern1, replacement1, content)
    
    # Pattern 2: or 0
    pattern2 = rf'(name="{item}_price"[^>]*value="{{\{{ design\.{item}_price) or 0 (}}\}}")'
    replacement2 = rf'\1 or default_prices.get("{item}", 0) \2'
    content = re.sub(pattern2, replacement2, content)
    
    # Pattern 3: or NUMBER (any hardcoded number)
    pattern3 = rf'(name="{item}_price"[^>]*value="{{\{{ design\.{item}_price) or \d+ (}}\}}")'
    replacement3 = rf'\1 or default_prices.get("{item}", 0) \2'
    content = re.sub(pattern3, replacement3, content)
    
    # Pattern 4: Fix any escaped quotes from previous runs
    content = content.replace(rf"default_prices.get(\'{item}\', 0)", f'default_prices.get("{item}", 0)')

# Add "Manage Default Prices" button if not already present
if 'Manage Default Prices' not in content:
    header_pattern = r'(<a href="{{\s*url_for\(\'leads\.admin_leads_list\'\)\s*}}" class="btn btn-light">.*?</a>)'
    header_replacement = r'''\1
                <a href="{{ url_for('leads.manage_default_prices') }}" class="btn btn-warning ms-2">
                    <i class="bi bi-gear"></i> Manage Default Prices
                </a>'''
    content = re.sub(header_pattern, header_replacement, content, flags=re.DOTALL)

# Write back
with open('templates/edit_lead_simple.html', 'w') as f:
    f.write(content)

print("✅ Template updated successfully!")
print("✅ All price fields now use default_prices from database")
print("✅ Added 'Manage Default Prices' button in header")
print("\nUpdated items:")
for item in items:
    print(f"  - {item}")

# Made with Bob
