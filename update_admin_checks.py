#!/usr/bin/env python3
"""
Script to update all admin checks in main.py from ADMIN_EMAILS to is_admin flag
"""

import re

# Read the file
with open('main.py', 'r') as f:
    content = f.read()

# Pattern to find the old admin check
old_pattern = r'if current_user\.email not in ADMIN_EMAILS:'
new_replacement = 'if not current_user.is_admin:'

# Replace all occurrences
updated_content = re.sub(old_pattern, new_replacement, content)

# Count replacements
count = len(re.findall(old_pattern, content))

# Write back
with open('main.py', 'w') as f:
    f.write(updated_content)

print(f"✅ Updated {count} admin checks in main.py")
print(f"   Changed: 'if current_user.email not in ADMIN_EMAILS:'")
print(f"   To:      'if not current_user.is_admin:'")

# Made with Bob
