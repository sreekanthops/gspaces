#!/usr/bin/env python3
"""
Script to update edit_lead_simple.html to use default prices from database
This fixes the issue where prices show as 0 instead of default values
"""

import re

# Read the template
with open('templates/edit_lead_simple.html', 'r') as f:
    content = f.read()

# Define all items and their database field names
items_mapping = {
    'table': 'table',
    'chair': 'chair', 
    'lighting': 'lighting',
    'storage': 'storage',
    'accessories': 'accessories',
    'big_plants': 'big_plants',
    'mini_plants': 'mini_plants',
    'frames': 'frames',
    'wall_racks': 'wall_racks',
    'desk_mat': 'desk_mat',
    'dustbin': 'dustbin',
    'floor_mat': 'floor_mat',
    'keyboard': 'keyboard',
    'mouse': 'mouse',
    'paint': 'paint',
    'wardrobes': 'wardrobes',
    'carpet': 'carpet',
    'curtains': 'curtains',
    'wall_art': 'wall_art',
    'desk_organizer': 'desk_organizer',
    'monitor_stand': 'monitor_stand',
    'cable_management': 'cable_management',
    'footrest': 'footrest',
    'monitor': 'monitor',
    'laptop_stand': 'laptop_stand',
    'headphone_stand': 'headphone_stand',
    'whiteboard': 'whiteboard',
    'bookshelf': 'bookshelf',
    'trash_bin': 'trash_bin',
    'desk_lamp': 'desk_lamp',
    'pen_holder': 'pen_holder',
    'laptop_holder': 'laptop_holder'
}

# Replace hardcoded prices with default_prices lookup
# Pattern: value="{{ design.ITEM_price or HARDCODED_NUMBER }}"
# Replace with: value="{{ design.ITEM_price or default_prices.get('ITEM', 0) }}"

for item_name in items_mapping.keys():
    # Pattern 1: Hardcoded number (e.g., or 12000)
    pattern1 = rf'value="{{\{{ design\.{item_name}_price or \d+ }}\}}"'
    replacement1 = f'value="{{{{ design.{item_name}_price or default_prices.get(\'{item_name}\', 0) }}}}"'
    content = re.sub(pattern1, replacement1, content)
    
    # Pattern 2: Just or 0
    pattern2 = rf'value="{{\{{ design\.{item_name}_price or 0 }}\}}"'
    replacement2 = f'value="{{{{ design.{item_name}_price or default_prices.get(\'{item_name}\', 0) }}}}"'
    content = re.sub(pattern2, replacement2, content)

# Add a "Set Default Prices" button in the header section
# Find the header section and add button
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

# Made with Bob
