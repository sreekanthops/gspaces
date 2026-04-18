-- Add user_id column to coupons table for personal coupons
-- NULL user_id = public coupon (everyone can use)
-- Non-NULL user_id = personal coupon (only that user can use)

ALTER TABLE coupons ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_coupons_user_id ON coupons(user_id);

-- Add a column to track if it's a personal coupon (for easier filtering)
ALTER TABLE coupons ADD COLUMN IF NOT EXISTS is_personal BOOLEAN DEFAULT FALSE;

-- Update existing coupons to be public (not personal)
UPDATE coupons SET is_personal = FALSE WHERE user_id IS NULL;

-- Add comment for clarity
COMMENT ON COLUMN coupons.user_id IS 'If NULL, coupon is public. If set, coupon is personal and only that user can use it.';
COMMENT ON COLUMN coupons.is_personal IS 'TRUE if coupon is personal (user-specific), FALSE if public (everyone can use)';

-- Made with Bob