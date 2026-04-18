-- ============================================
-- WALLET & REFERRAL SYSTEM MIGRATION
-- ============================================
-- This script adds wallet functionality and referral system to the gspaces database

-- 1. Add wallet balance to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_balance DECIMAL(10, 2) DEFAULT 0.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_bonus_limit DECIMAL(10, 2) DEFAULT 10000.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code VARCHAR(20) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by_user_id INTEGER REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS signup_bonus_credited BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_order_completed BOOLEAN DEFAULT FALSE;

-- 2. Create wallet_transactions table to track all wallet activities
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL, -- 'credit', 'debit', 'bonus', 'refund', 'referral_bonus'
    amount DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    description TEXT,
    reference_type VARCHAR(50), -- 'order', 'signup', 'referral', 'first_order', 'admin'
    reference_id INTEGER, -- order_id or related reference
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB -- Store additional data like referrer info, coupon details, etc.
);

-- 3. Create referral_coupons table for user-specific referral codes
CREATE TABLE IF NOT EXISTS referral_coupons (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_code VARCHAR(20) UNIQUE NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 5.00, -- 5% discount
    referral_bonus_percentage DECIMAL(5, 2) DEFAULT 5.00, -- 5% bonus to referrer
    times_used INTEGER DEFAULT 0,
    total_referral_earnings DECIMAL(10, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- 1 month from creation
    CONSTRAINT unique_user_referral UNIQUE(user_id)
);

-- 4. Create coupon_usage table to track who used which coupon
CREATE TABLE IF NOT EXISTS coupon_usage (
    id SERIAL PRIMARY KEY,
    coupon_code VARCHAR(50) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    discount_amount DECIMAL(10, 2) NOT NULL,
    referrer_bonus_amount DECIMAL(10, 2) DEFAULT 0.00,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_coupon_usage UNIQUE(user_id, coupon_code)
);

-- 5. Add wallet-related columns to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS wallet_amount_used DECIMAL(10, 2) DEFAULT 0.00;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS final_paid_amount DECIMAL(10, 2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cashback_earned DECIMAL(10, 2) DEFAULT 0.00;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cashback_credited BOOLEAN DEFAULT FALSE;

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_referral_coupons_code ON referral_coupons(coupon_code);
CREATE INDEX IF NOT EXISTS idx_referral_coupons_user_id ON referral_coupons(user_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_user_id ON coupon_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon_code ON coupon_usage(coupon_code);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);

-- 7. Create function to generate unique referral code based on username
CREATE OR REPLACE FUNCTION generate_referral_code(user_name TEXT, user_id INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    base_code VARCHAR(20);
    final_code VARCHAR(20);
    counter INTEGER := 0;
BEGIN
    -- Create base code from username (first 6 chars uppercase + user_id)
    base_code := UPPER(SUBSTRING(REGEXP_REPLACE(user_name, '[^a-zA-Z0-9]', '', 'g'), 1, 6)) || user_id;
    final_code := base_code;
    
    -- Check if code exists and add counter if needed
    WHILE EXISTS (SELECT 1 FROM users WHERE referral_code = final_code) LOOP
        counter := counter + 1;
        final_code := base_code || counter;
    END LOOP;
    
    RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger to auto-generate referral code on user creation
CREATE OR REPLACE FUNCTION auto_generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code(NEW.name, NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_referral_code ON users;
CREATE TRIGGER trigger_auto_referral_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_referral_code();

-- 9. Update existing users to have referral codes
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id, name FROM users WHERE referral_code IS NULL LOOP
        UPDATE users 
        SET referral_code = generate_referral_code(user_record.name, user_record.id)
        WHERE id = user_record.id;
    END LOOP;
END $$;

-- 10. Create referral coupons for existing users
INSERT INTO referral_coupons (user_id, coupon_code, expires_at)
SELECT 
    id, 
    referral_code,
    CURRENT_TIMESTAMP + INTERVAL '1 month'
FROM users
WHERE referral_code IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- 11. Create view for wallet summary
CREATE OR REPLACE VIEW wallet_summary AS
SELECT 
    u.id as user_id,
    u.name,
    u.email,
    u.wallet_balance,
    u.wallet_bonus_limit,
    u.referral_code,
    rc.times_used as referral_uses,
    rc.total_referral_earnings,
    COUNT(DISTINCT wt.id) as total_transactions,
    COALESCE(SUM(CASE WHEN wt.transaction_type = 'credit' THEN wt.amount ELSE 0 END), 0) as total_credits,
    COALESCE(SUM(CASE WHEN wt.transaction_type = 'debit' THEN wt.amount ELSE 0 END), 0) as total_debits
FROM users u
LEFT JOIN referral_coupons rc ON u.id = rc.user_id
LEFT JOIN wallet_transactions wt ON u.id = wt.user_id
GROUP BY u.id, u.name, u.email, u.wallet_balance, u.wallet_bonus_limit, u.referral_code, rc.times_used, rc.total_referral_earnings;

COMMENT ON TABLE wallet_transactions IS 'Tracks all wallet transactions including credits, debits, bonuses, and referrals';
COMMENT ON TABLE referral_coupons IS 'User-specific referral codes with 1-month expiry';
COMMENT ON TABLE coupon_usage IS 'Tracks coupon usage to prevent duplicate usage by same user';
COMMENT ON COLUMN users.wallet_balance IS 'Current wallet balance available for use';
COMMENT ON COLUMN users.wallet_bonus_limit IS 'Maximum bonus amount that can be used per order (default 10000)';
COMMENT ON COLUMN users.referral_code IS 'Unique referral code for each user';
COMMENT ON COLUMN orders.wallet_amount_used IS 'Amount paid from wallet for this order';
COMMENT ON COLUMN orders.cashback_earned IS 'Cashback earned on first order (5% of order value)';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Wallet and Referral System migration completed successfully!';
    RAISE NOTICE 'Features added:';
    RAISE NOTICE '  - Wallet balance tracking';
    RAISE NOTICE '  - Signup bonus (₹500)';
    RAISE NOTICE '  - First order cashback (5%%)';
    RAISE NOTICE '  - Referral system with unique codes';
    RAISE NOTICE '  - Referral bonus (5%% for both parties)';
    RAISE NOTICE '  - Wallet transaction history';
    RAISE NOTICE '  - Bonus usage limit (₹10,000 per order)';
END $$;

-- Made with Bob
