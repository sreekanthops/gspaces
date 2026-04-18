-- Create missing referral coupon for GSPACE32
-- User: gspaces (ID: 32)

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
VALUES (
    32,                                          -- user_id for gspaces
    'GSPACE32',                                  -- coupon_code
    5.00,                                        -- 5% discount for referred user
    5.00,                                        -- 5% bonus for referrer
    0,                                           -- times_used (starting at 0)
    0.00,                                        -- total_referral_earnings
    true,                                        -- is_active
    NOW(),                                       -- created_at
    NOW() + INTERVAL '30 days'                   -- expires_at (30 days from now)
)
ON CONFLICT (user_id) DO UPDATE SET
    coupon_code = EXCLUDED.coupon_code,
    is_active = true,
    expires_at = NOW() + INTERVAL '30 days';

-- Verify the insertion
SELECT 
    id, 
    user_id, 
    coupon_code, 
    discount_percentage, 
    is_active, 
    expires_at 
FROM referral_coupons 
WHERE coupon_code = 'GSPACE32';

-- Made with Bob
