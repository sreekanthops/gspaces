#!/bin/bash

echo "=========================================="
echo "Checking Template Version on Server"
echo "=========================================="

echo ""
echo "Checking if feedback section exists in template..."
if grep -q "existingFeedback" templates/quotation_view_simple.html; then
    echo "✓ Feedback section found in template"
    echo ""
    echo "Checking for version marker..."
    if grep -q "Feedback feature v2.0" templates/quotation_view_simple.html; then
        echo "✓ Version v2.0 marker found"
    else
        echo "✗ Version marker NOT found - template may not be updated"
    fi
else
    echo "✗ Feedback section NOT found in template"
    echo "Template needs to be updated!"
fi

echo ""
echo "Checking git status..."
git log -1 --oneline

echo ""
echo "Last template modification:"
ls -lh templates/quotation_view_simple.html

echo ""
echo "=========================================="

# Made with Bob
