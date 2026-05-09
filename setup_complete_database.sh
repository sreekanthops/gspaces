#!/bin/bash

# Complete Database Setup Script for GSpaces
# This sets up all required tables including animated furniture

echo "🔧 Setting up complete GSpaces database..."

DB_USER="sri"
DB_NAME="gspaces"
export PGPASSWORD="gspaces2025"

echo "📊 Creating animated furniture tables..."
psql -U $DB_USER -d $DB_NAME -f create_animated_furniture_table.sql

echo "📊 Creating OTP verification table..."
psql -U $DB_USER -d $DB_NAME -f create_otp_table.sql

echo "📊 Checking if products table needs review_count column..."
psql -U $DB_USER -d $DB_NAME << EOF
-- Add review_count column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='products' AND column_name='review_count'
    ) THEN
        ALTER TABLE products ADD COLUMN review_count INTEGER DEFAULT 0;
        COMMENT ON COLUMN products.review_count IS 'Number of reviews for this product';
    END IF;
END \$\$;

-- Add rating column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='products' AND column_name='rating'
    ) THEN
        ALTER TABLE products ADD COLUMN rating DECIMAL(3,2) DEFAULT 0.00;
        COMMENT ON COLUMN products.rating IS 'Average rating (0.00 to 5.00)';
    END IF;
END \$\$;
EOF

echo "✅ Database setup complete!"
echo ""
echo "🎨 Animated Furniture System Ready!"
echo "   - Access: http://localhost:5000/admin/animated-furniture"
echo "   - Test page: http://localhost:5000/test-animated-banner"
echo ""
echo "📝 Next steps:"
echo "   1. Login as admin"
echo "   2. Go to Animated Furniture section"
echo "   3. Upload PNG furniture images"
echo "   4. Configure animation settings"
echo "   5. Items will appear on homepage!"

# Made with Bob
