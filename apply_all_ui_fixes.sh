#!/bin/bash

echo "=========================================="
echo "Applying All UI Fixes"
echo "=========================================="
echo ""

# Step 1: Add mobile responsive fixes to login_new.html
echo "Step 1: Adding mobile responsive CSS fixes to login..."
cat > /tmp/login_media_queries.txt << 'EOF'
  @media (max-width: 968px) {
    .login-container {
      flex-direction: column;
      padding: 30px;
      gap: 30px;
      height: auto;
      min-height: auto;
    }

    .image-section {
      min-height: 350px;
    }

    .form-section {
      padding: 20px;
    }

    .form-section h2 {
      font-size: 28px;
    }
  }

  @media (max-width: 480px) {
    body {
      padding: 20px 10px;
    }

    .login-container {
      padding: 20px;
      border-radius: 20px;
      height: auto;
      min-height: auto;
    }

    .image-section {
      min-height: 250px;
    }

    .form-section {
      padding: 15px 10px;
    }

    .form-section h2 {
      font-size: 24px;
    }

    .brand-header {
      margin-bottom: 30px;
    }

    .brand-header img {
      height: 32px;
    }

    .brand-name {
      font-size: 18px;
    }

    .form-section .subtitle {
      font-size: 14px;
      margin-bottom: 24px;
    }

    .form-group {
      margin-bottom: 16px;
    }

    .form-group input {
      padding: 12px 16px;
      font-size: 14px;
    }

    .btn-primary {
      padding: 14px;
      font-size: 15px;
    }

    .divider {
      margin: 20px 0;
    }

    .btn-social {
      padding: 12px;
      font-size: 14px;
    }

    .signup-link {
      margin-top: 20px;
      font-size: 13px;
    }
  }
EOF

# Replace the media queries section in login_new.html
sed -i.bak '/^  @media (max-width: 968px)/,/^  }$/d' templates/login_new.html
sed -i.bak '/^<\/style>$/i\
' templates/login_new.html
cat /tmp/login_media_queries.txt >> templates/login_new.html
echo "</style>" >> templates/login_new.html

echo "✓ Mobile responsive CSS added"
echo ""

# Step 2: Rename _new files to original
echo "Step 2: Renaming template files..."
mkdir -p templates/backup_$(date +%Y%m%d_%H%M%S)

if [ -f "templates/login.html" ]; then
    mv templates/login.html templates/backup_$(date +%Y%m%d_%H%M%S)/
fi
mv templates/login_new.html templates/login.html
echo "✓ login_new.html → login.html"

if [ -f "templates/signup.html" ]; then
    mv templates/signup.html templates/backup_$(date +%Y%m%d_%H%M%S)/
fi
if [ -f "templates/signup_new.html" ]; then
    mv templates/signup_new.html templates/signup.html
    echo "✓ signup_new.html → signup.html"
fi

if [ -f "templates/contact.html" ]; then
    mv templates/contact.html templates/backup_$(date +%Y%m%d_%H%M%S)/
fi
if [ -f "templates/contact_new.html" ]; then
    mv templates/contact_new.html templates/contact.html
    echo "✓ contact_new.html → contact.html"
fi

if [ -f "templates/corporate_new.html" ]; then
    mv templates/corporate_new.html templates/corporate.html
    echo "✓ corporate_new.html → corporate.html"
fi

if [ -f "templates/products_new.html" ]; then
    mv templates/products_new.html templates/products.html
    echo "✓ products_new.html → products.html"
fi

echo ""

# Step 3: Update main.py references
echo "Step 3: Updating main.py references..."
cp main.py main.py.backup_$(date +%Y%m%d_%H%M%S)

sed -i.bak "s/login_new\.html/login.html/g" main.py
sed -i.bak "s/signup_new\.html/signup.html/g" main.py
sed -i.bak "s/contact_new\.html/contact.html/g" main.py
sed -i.bak "s/corporate_new\.html/corporate.html/g" main.py
sed -i.bak "s/products_new\.html/products.html/g" main.py
rm -f main.py.bak

echo "✓ main.py updated"
echo ""

# Cleanup
rm -f /tmp/login_media_queries.txt
rm -f templates/*.bak

echo "=========================================="
echo "✅ All UI Fixes Applied!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "1. Added mobile responsive CSS to login page"
echo "2. Renamed all _new templates to original names"
echo "3. Updated all main.py references"
echo "4. Login background changed to banner.jpg"
echo ""
echo "Ready to commit and push!"

# Made with Bob
