-- Upgrade referral_coupons table to support both fixed and percentage discounts
-- This gives admin full control over referral coupon amounts

-- Add new columns for flexible discount control
ALTER TABLE referral_coupons
ADD COLUMN IF NOT EXISTS discount_type VARCHAR(20) DEFAULT 'percentage',  -- 'percentage' or 'fixed'
ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10, 2) DEFAULT 0.00,     -- Fixed amount (e.g., 1000)
ADD COLUMN IF NOT EXISTS referrer_bonus_type VARCHAR(20) DEFAULT 'percentage',  -- 'percentage' or 'fixed'
ADD COLUMN IF NOT EXISTS referrer_bonus_amount DECIMAL(10, 2) DEFAULT 0.00,     -- Fixed bonus amount
ADD COLUMN IF NOT EXISTS min_order_amount DECIMAL(10, 2) DEFAULT 0.00,    -- Minimum order to use coupon
ADD COLUMN IF NOT EXISTS max_discount_amount DECIMAL(10, 2),              -- Max discount cap
ADD COLUMN IF NOT EXISTS first_order_only BOOLEAN DEFAULT false,          -- Only for first-time users
ADD COLUMN IF NOT EXISTS usage_limit INTEGER,                             -- Max times this code can be used
ADD COLUMN IF NOT EXISTS per_user_limit INTEGER DEFAULT 1,                -- Max times per user
ADD COLUMN IF NOT EXISTS description TEXT;                                -- Admin notes

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_referral_coupons_code ON referral_coupons(coupon_code);
CREATE INDEX IF NOT EXISTS idx_referral_coupons_active ON referral_coupons(is_active);

-- Update existing records to use fixed amounts (₹1000 for both)
UPDATE referral_coupons
SET 
    discount_type = 'fixed',
    discount_amount = 1000.00,
    referrer_bonus_type = 'fixed',
    referrer_bonus_amount = 1000.00,
    description = 'Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer'
WHERE discount_type IS NULL OR discount_type = 'percentage';

-- Show updated structure
\d referral_coupons

-- Show sample data
SELECT 
    id,
    user_id,
    coupon_code,
    discount_type,
    discount_amount,
    discount_percentage,
    referrer_bonus_type,
    referrer_bonus_amount,
    is_active,
    expires_at
FROM referral_coupons
LIMIT 5;

-- Made with Bob
