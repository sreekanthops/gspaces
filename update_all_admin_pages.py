#!/usr/bin/env python3
"""
Script to update all remaining admin pages with consistent sidebar layout
"""

import re
import os

# Files to update with their active_page values
files_to_update = {
    'templates/admin_referral_coupons.html': 'referral',
    'templates/admin_customers.html': 'customers',
    'templates/admin_deals.html': 'deals',
    'templates/admin_gst_settings.html': 'gst',
    'templates/admin_blogs.html': 'blogs',
}

# Pattern to find the old structure
old_pattern_1 = r'<body>\s*{% include \'navbar\.html\' %}\s*(?:{% include \'admin_nav\.html\' %}\s*)?'
old_pattern_2 = r'<div class="(?:container|admin-container)"[^>]*>\s*(?:{% set active_page = \'[^\']+\' %}\s*)?(?:{% include \'admin_nav\.html\' %}\s*)?'

# New structure template
new_structure = '''<body>
    {% include 'navbar.html' %}
    
    <div class="container-fluid" style="margin-top: 76px;">
        <div class="row g-0">
            <!-- Sidebar -->
            <div class="col-md-2">
                {% set active_page = '{active_page}' %}
                {% include 'admin_sidebar.html' %}
            </div>

            <!-- Main Content -->
            <div class="col-md-10 p-4" style="background: #f8f9fa; min-height: calc(100vh - 76px);">'''

# Closing divs to add before </body>
closing_divs = '''            </div>
        </div>
    </div>'''

def update_file(filepath, active_page):
    """Update a single admin file with the new layout"""
    print(f"Updating {filepath}...")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace the opening structure
        content = re.sub(
            r'<body>\s*{% include \'navbar\.html\' %}.*?(?=<div class="(?:page-header|admin-card|admin-container))',
            new_structure.format(active_page=active_page) + '\n                ',
            content,
            flags=re.DOTALL
        )
        
        # Add closing divs before </body> if not already there
        if closing_divs not in content:
            content = content.replace('</body>', closing_divs + '\n\n    <script', 1)
            content = content.replace(closing_divs + '\n\n    <script', closing_divs + '\n\n    <script')
        
        # Write back
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ Successfully updated {filepath}")
        return True
        
    except Exception as e:
        print(f"✗ Error updating {filepath}: {e}")
        return False

def main():
    print("=" * 60)
    print("Updating Admin Pages with Consistent Sidebar Layout")
    print("=" * 60)
    print()
    
    success_count = 0
    for filepath, active_page in files_to_update.items():
        if os.path.exists(filepath):
            if update_file(filepath, active_page):
                success_count += 1
        else:
            print(f"✗ File not found: {filepath}")
    
    print()
    print("=" * 60)
    print(f"Updated {success_count}/{len(files_to_update)} files successfully")
    print("=" * 60)

if __name__ == '__main__':
    main()

# Made with Bob
