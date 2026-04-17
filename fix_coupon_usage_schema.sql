-- Fix coupon_usage table schema mismatch
-- The table has coupon_id but code expects coupon_code

-- Check current structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'coupon_usage'
ORDER BY ordinal_position;

-- Add coupon_code column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coupon_usage' AND column_name = 'coupon_code'
    ) THEN
        ALTER TABLE coupon_usage ADD COLUMN coupon_code VARCHAR(50);
        RAISE NOTICE 'Added coupon_code column';
        
        -- If there's data, try to populate coupon_code from coupons table
        UPDATE coupon_usage cu
        SET coupon_code = c.code
        FROM coupons c
        WHERE cu.coupon_id = c.id
        AND cu.coupon_code IS NULL;
        
        RAISE NOTICE 'Populated coupon_code from coupons table';
    ELSE
        RAISE NOTICE 'coupon_code column already exists';
    END IF;
END $$;

-- Verify the fix
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'coupon_usage'
ORDER BY ordinal_position;

-- Made with Bob
