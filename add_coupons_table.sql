-- Create coupons table
CREATE TABLE IF NOT EXISTS coupons (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2) NOT NULL,
    description TEXT,
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount_amount DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    usage_limit INTEGER,
    times_used INTEGER DEFAULT 0,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255)
);

-- Insert sample coupons
INSERT INTO coupons (code, discount_type, discount_value, description, min_order_amount, is_active, created_by)
VALUES 
    ('NEWGSPACES', 'percentage', 5.00, '5% discount for new customers', 0, TRUE, 'sri.chityala501@gmail.com'),
    ('DEEWALIFEST', 'percentage', 2.00, '2% Diwali festival discount', 0, TRUE, 'sri.chityala501@gmail.com'),
    ('DASARAFEST', 'fixed', 1000.00, '₹1000 off on Dasara festival', 0, TRUE, 'sri.chityala501@gmail.com')
ON CONFLICT (code) DO NOTHING;

-- Create coupon usage tracking table
CREATE TABLE IF NOT EXISTS coupon_usage (
    id SERIAL PRIMARY KEY,
    coupon_id INTEGER NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
    discount_applied DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(coupon_id, order_id)
);

-- Add coupon columns to orders table if they don't exist
ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_code VARCHAR(50);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_discount DECIMAL(10, 2) DEFAULT 0;

-- Made with Bob
