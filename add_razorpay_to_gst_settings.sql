-- Add Razorpay credentials to GST settings table
ALTER TABLE gst_settings 
ADD COLUMN IF NOT EXISTS razorpay_key_gst VARCHAR(100),
ADD COLUMN IF NOT EXISTS razorpay_secret_gst VARCHAR(100),
ADD COLUMN IF NOT EXISTS razorpay_key_no_gst VARCHAR(100),
ADD COLUMN IF NOT EXISTS razorpay_secret_no_gst VARCHAR(100);

-- Update with current default values (you should update these with actual credentials)
UPDATE gst_settings 
SET 
    razorpay_key_gst = 'rzp_live_R6wg6buSedSnTV',
    razorpay_secret_gst = 'your_gst_secret_key_here',
    razorpay_key_no_gst = 'rzp_live_R6wg6buSedSnTV',
    razorpay_secret_no_gst = 'your_no_gst_secret_key_here'
WHERE id = (SELECT id FROM gst_settings ORDER BY id DESC LIMIT 1);

-- Made with Bob
