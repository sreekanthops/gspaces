-- ============================================
-- Admin Order Setup Feature - Database Schema
-- ============================================
-- This script adds columns to support admin-created orders
-- without payment requirements

-- Add new columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS order_source VARCHAR(50) DEFAULT 'customer',
ADD COLUMN IF NOT EXISTS customer_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS admin_created_by INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS requires_payment BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS admin_notes TEXT,
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(50);

-- Add comments for documentation
COMMENT ON COLUMN orders.order_source IS 'Source of order: customer, admin_created, phone_order, etc.';
COMMENT ON COLUMN orders.customer_type IS 'Type: walk-in, phone_order, referral, repeat_customer, corporate';
COMMENT ON COLUMN orders.admin_created_by IS 'Admin user ID who created this order';
COMMENT ON COLUMN orders.requires_payment IS 'Whether this order requires payment processing';
COMMENT ON COLUMN orders.admin_notes IS 'Internal notes from admin about this order';
COMMENT ON COLUMN orders.customer_name IS 'Customer name for admin-created orders';
COMMENT ON COLUMN orders.customer_phone IS 'Customer phone for admin-created orders';

-- Create index for faster queries on admin orders
CREATE INDEX IF NOT EXISTS idx_orders_order_source ON orders(order_source);
CREATE INDEX IF NOT EXISTS idx_orders_admin_created_by ON orders(admin_created_by);
CREATE INDEX IF NOT EXISTS idx_orders_customer_type ON orders(customer_type);
CREATE INDEX IF NOT EXISTS idx_orders_requires_payment ON orders(requires_payment);

-- Make razorpay fields and user_id nullable for admin orders
ALTER TABLE orders
ALTER COLUMN razorpay_order_id DROP NOT NULL,
ALTER COLUMN razorpay_payment_id DROP NOT NULL,
ALTER COLUMN user_id DROP NOT NULL;

-- Drop foreign key constraint on user_email to allow admin orders with non-registered customer emails
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_user_email_fkey;

-- Update existing orders to have default values
UPDATE orders 
SET order_source = 'customer', 
    requires_payment = true 
WHERE order_source IS NULL;

-- Create order_status_history table for tracking status changes
CREATE TABLE IF NOT EXISTS order_status_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by INTEGER REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    notification_sent BOOLEAN DEFAULT false
);

-- Add index for order status history
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_changed_at ON order_status_history(changed_at);

-- Create email_notifications table for tracking sent emails
CREATE TABLE IF NOT EXISTS email_notifications (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    recipient_email VARCHAR(255),
    recipient_phone VARCHAR(50),
    subject VARCHAR(255),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT
);

-- Add index for email notifications
CREATE INDEX IF NOT EXISTS idx_email_notifications_order_id ON email_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_sent_at ON email_notifications(sent_at);

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON orders TO your_app_user;
-- GRANT SELECT, INSERT ON order_status_history TO your_app_user;
-- GRANT SELECT, INSERT ON email_notifications TO your_app_user;

-- Verification queries
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'orders' 
-- AND column_name IN ('order_source', 'customer_type', 'admin_created_by', 'requires_payment', 'admin_notes', 'customer_name', 'customer_phone');

COMMENT ON TABLE order_status_history IS 'Tracks all status changes for orders with timestamps and user info';
COMMENT ON TABLE email_notifications IS 'Logs all email notifications sent for orders';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Admin Order Setup schema created successfully!';
    RAISE NOTICE 'New columns added to orders table';
    RAISE NOTICE 'Created order_status_history table';
    RAISE NOTICE 'Created email_notifications table';
END $$;

-- Made with Bob
