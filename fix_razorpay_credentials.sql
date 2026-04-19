-- Fix Razorpay credentials in gst_settings table
-- This updates the database with the correct default Razorpay credentials

UPDATE gst_settings 
SET 
    razorpay_key_gst = 'rzp_live_R6wg6buSedSnTV',
    razorpay_secret_gst = 'xeBC7q5tEirlDg4y4Tc3JEc3',
    razorpay_key_no_gst = 'rzp_live_R6wg6buSedSnTV',
    razorpay_secret_no_gst = 'xeBC7q5tEirlDg4y4Tc3JEc3'
WHERE id = (SELECT id FROM gst_settings ORDER BY id DESC LIMIT 1);

-- Verify the update
SELECT gst_enabled, razorpay_key_gst, razorpay_key_no_gst FROM gst_settings;

-- Made with Bob
