-- Create GST settings table
CREATE TABLE IF NOT EXISTS gst_settings (
    id SERIAL PRIMARY KEY,
    gst_enabled BOOLEAN DEFAULT TRUE,
    gst_rate DECIMAL(5,4) DEFAULT 0.18,
    gst_number VARCHAR(20) DEFAULT '36AORPG7724G1ZN',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(255)
);

-- Insert default GST settings
INSERT INTO gst_settings (gst_enabled, gst_rate, gst_number, updated_by)
VALUES (TRUE, 0.18, '36AORPG7724G1ZN', 'system')
ON CONFLICT DO NOTHING;

-- Made with Bob
