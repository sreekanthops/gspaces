#!/bin/bash

# User Workspace Feature Deployment Script
# This script stages and commits all changes for the user-specific workspace feature

echo "=========================================="
echo "User Workspace Feature Deployment"
echo "=========================================="
echo ""

# Check if we're on the animate branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "animate" ]; then
    echo "⚠️  Warning: Not on 'animate' branch"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

echo ""
echo "Step 1: Checking file status..."
echo "----------------------------------------"
git status --short

echo ""
echo "Step 2: Staging database schema..."
echo "----------------------------------------"
git add create_user_workspaces_table.sql
echo "✓ Added: create_user_workspaces_table.sql"

echo ""
echo "Step 3: Staging template files..."
echo "----------------------------------------"
git add templates/navbar.html
echo "✓ Added: templates/navbar.html (Animate menu)"
git add templates/my_workspace.html
echo "✓ Added: templates/my_workspace.html (New workspace page)"

echo ""
echo "Step 4: Staging JavaScript files..."
echo "----------------------------------------"
git add static/js/workspace.js
echo "✓ Added: static/js/workspace.js (Workspace handler)"

echo ""
echo "Step 5: Staging backend routes..."
echo "----------------------------------------"
git add main.py
echo "✓ Added: main.py (Workspace API routes)"

echo ""
echo "Step 6: Staging documentation..."
echo "----------------------------------------"
git add USER_WORKSPACE_IMPLEMENTATION.md
echo "✓ Added: USER_WORKSPACE_IMPLEMENTATION.md"

echo ""
echo "Step 7: Review staged changes..."
echo "----------------------------------------"
git diff --cached --stat

echo ""
echo "=========================================="
echo "Files staged successfully!"
echo "=========================================="
echo ""
echo "Summary of changes:"
echo "  • Database: User workspace items table"
echo "  • Frontend: Navbar with Animate menu (login required)"
echo "  • Frontend: User workspace page with upload UI"
echo "  • Frontend: Workspace JavaScript handler"
echo "  • Backend: 5 new API routes for workspace management"
echo "  • Docs: Implementation guide"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff --cached"
echo "  2. Commit: git commit -m 'Add user-specific workspace feature'"
echo "  3. Push: git push origin animate"
echo ""
echo "To commit now, run:"
echo "  git commit -m 'feat: Add user-specific workspace feature with upload and auto-save'"
echo ""

# Ask if user wants to commit now
read -p "Do you want to commit these changes now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Committing changes..."
    git commit -m "feat: Add user-specific workspace feature

- Created user_workspace_items table for per-user furniture storage
- Added 'Animate' menu item in navbar (login required)
- Built my_workspace.html with drag-and-drop upload UI
- Implemented workspace.js for file upload and auto-save
- Added 5 API routes: upload, save, delete, clear workspace
- Base64 image storage for portability
- Auto-save on drag/rotate with 2-second debounce
- User isolation: each user sees only their own items
- Real-time stats display and notifications

Closes issue with quotation page auto-slide not working by
implementing proper user-specific workspace feature."
    
    echo ""
    echo "✓ Changes committed successfully!"
    echo ""
    
    # Ask if user wants to push
    read -p "Do you want to push to GitHub now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Pushing to GitHub..."
        git push origin animate
        echo ""
        echo "✓ Changes pushed to GitHub!"
        echo ""
        echo "=========================================="
        echo "Deployment Complete! 🎉"
        echo "=========================================="
    else
        echo ""
        echo "Skipped push. To push later, run:"
        echo "  git push origin animate"
    fi
else
    echo ""
    echo "Skipped commit. To commit later, run:"
    echo "  git commit -m 'feat: Add user-specific workspace feature'"
fi

echo ""
echo "Done!"

# Made with Bob
