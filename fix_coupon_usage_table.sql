-- Fix coupon_usage table - add missing columns
-- Run this if you get error: column cu.discount_amount does not exist

-- Check if columns exist and add them if missing
DO $$
BEGIN
    -- Add discount_amount column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coupon_usage' AND column_name = 'discount_amount'
    ) THEN
        ALTER TABLE coupon_usage ADD COLUMN discount_amount DECIMAL(10, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added discount_amount column to coupon_usage table';
    ELSE
        RAISE NOTICE 'discount_amount column already exists';
    END IF;

    -- Add referrer_bonus_amount column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coupon_usage' AND column_name = 'referrer_bonus_amount'
    ) THEN
        ALTER TABLE coupon_usage ADD COLUMN referrer_bonus_amount DECIMAL(10, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added referrer_bonus_amount column to coupon_usage table';
    ELSE
        RAISE NOTICE 'referrer_bonus_amount column already exists';
    END IF;
END $$;

-- Verify the fix
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'coupon_usage'
ORDER BY ordinal_position;

-- Made with Bob
