-- Add wallet coupon support to coupons table
-- This migration adds:
-- 1. coupon_type: Determines if coupon can be used for orders, wallet top-up, or both
-- 2. expiry_type: Determines if coupon has expiry date or is non-expiring
-- 3. user_id: For personal coupons (NULL for public coupons)

-- Add coupon_type column
ALTER TABLE coupons 
ADD COLUMN IF NOT EXISTS coupon_type VARCHAR(20) DEFAULT 'order' 
CHECK (coupon_type IN ('order', 'wallet', 'both'));

-- Add expiry_type column
ALTER TABLE coupons 
ADD COLUMN IF NOT EXISTS expiry_type VARCHAR(20) DEFAULT 'expiry' 
CHECK (expiry_type IN ('expiry', 'non_expiry'));

-- Add user_id column for personal coupons (if not exists)
ALTER TABLE coupons 
ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Update coupon_usage table to track wallet redemptions
ALTER TABLE coupon_usage 
ADD COLUMN IF NOT EXISTS usage_type VARCHAR(20) DEFAULT 'order' 
CHECK (usage_type IN ('order', 'wallet'));

-- Make order_id nullable since wallet coupons won't have orders
ALTER TABLE coupon_usage 
ALTER COLUMN order_id DROP NOT NULL;

-- Update the unique constraint to allow multiple wallet redemptions tracking
-- but still prevent duplicate order usage
ALTER TABLE coupon_usage 
DROP CONSTRAINT IF EXISTS coupon_usage_coupon_id_order_id_key;

-- Add new constraint: one coupon per user (for wallet) or one coupon per order
ALTER TABLE coupon_usage 
ADD CONSTRAINT unique_coupon_user_usage 
UNIQUE (coupon_id, user_id, usage_type);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_coupon_usage_user_type 
ON coupon_usage(user_id, usage_type);

CREATE INDEX IF NOT EXISTS idx_coupons_type 
ON coupons(coupon_type);

-- Insert sample wallet coupon for Instagram followers
INSERT INTO coupons (
    code, 
    discount_type, 
    discount_value, 
    description, 
    min_order_amount, 
    is_active, 
    coupon_type,
    expiry_type,
    valid_until,
    created_by
)
VALUES (
    'GSPACES_DESKS_FOLLOW', 
    'fixed', 
    1000.00, 
    '₹1000 wallet bonus for Instagram followers', 
    0, 
    TRUE,
    'wallet',
    'expiry',
    CURRENT_TIMESTAMP + INTERVAL '30 days',
    'admin'
)
ON CONFLICT (code) DO UPDATE SET
    discount_value = EXCLUDED.discount_value,
    description = EXCLUDED.description,
    coupon_type = EXCLUDED.coupon_type,
    expiry_type = EXCLUDED.expiry_type,
    valid_until = EXCLUDED.valid_until;

-- Made with Bob