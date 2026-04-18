-- Create referral coupons for ALL users who don't have them yet
-- This is a one-time fix for existing users

INSERT INTO referral_coupons (
    user_id, 
    coupon_code, 
    discount_percentage, 
    referral_bonus_percentage, 
    times_used, 
    total_referral_earnings, 
    is_active, 
    created_at, 
    expires_at
)
SELECT 
    u.id,                                        -- user_id
    u.referral_code,                             -- coupon_code from users table
    5.00,                                        -- 5% discount for referred user
    5.00,                                        -- 5% bonus for referrer
    0,                                           -- times_used (starting at 0)
    0.00,                                        -- total_referral_earnings
    true,                                        -- is_active
    NOW(),                                       -- created_at
    NOW() + INTERVAL '365 days'                  -- expires_at (1 year from now)
FROM users u
WHERE u.referral_code IS NOT NULL                -- Only users with referral codes
  AND NOT EXISTS (                               -- But don't have referral coupon yet
      SELECT 1 
      FROM referral_coupons rc 
      WHERE rc.user_id = u.id
  );

-- Show results
SELECT 
    COUNT(*) as total_referral_coupons_created
FROM referral_coupons;

-- Show all referral coupons
SELECT 
    rc.id,
    rc.user_id,
    u.name,
    u.email,
    rc.coupon_code,
    rc.is_active,
    rc.expires_at
FROM referral_coupons rc
JOIN users u ON rc.user_id = u.id
ORDER BY rc.id DESC
LIMIT 20;

-- Made with Bob
