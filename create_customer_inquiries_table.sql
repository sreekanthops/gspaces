-- Create customer_inquiries table for lead management
CREATE TABLE IF NOT EXISTS customer_inquiries (
    id SERIAL PRIMARY KEY,
    
    -- Basic Information
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    
    -- Setup Requirements
    setup_type VARCHAR(100) NOT NULL, -- 'office', 'studio', 'wfh', 'other'
    setup_type_other TEXT, -- if setup_type is 'other'
    
    -- Budget
    budget_range VARCHAR(50) NOT NULL, -- 'under_25k', '25k_50k', '50k_100k', '100k_500k', '500k_plus', 'not_decided'
    
    -- Quantity/Scale
    quantity_scale VARCHAR(50) NOT NULL, -- 'single', '2_10', '10_50', '50_plus'
    
    -- Timeline
    timeline VARCHAR(50) NOT NULL, -- 'immediate', '1_2_weeks', '1_month', 'flexible'
    
    -- Additional Details
    additional_requirements TEXT,
    
    -- File Uploads
    layout_photo VARCHAR(500), -- path to uploaded layout/room photo
    reference_images TEXT, -- JSON array of reference image paths
    
    -- Contact Preferences
    preferred_contact_time VARCHAR(100),
    wants_consultation BOOLEAN DEFAULT false,
    
    -- Metadata
    status VARCHAR(50) DEFAULT 'new', -- 'new', 'contacted', 'quoted', 'converted', 'closed'
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Optional: Link to user if logged in
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_customer_inquiries_status ON customer_inquiries(status);
CREATE INDEX IF NOT EXISTS idx_customer_inquiries_created_at ON customer_inquiries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_inquiries_budget ON customer_inquiries(budget_range);
CREATE INDEX IF NOT EXISTS idx_customer_inquiries_setup_type ON customer_inquiries(setup_type);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customer_inquiry_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_inquiry_timestamp
    BEFORE UPDATE ON customer_inquiries
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_inquiry_timestamp();

-- Made with Bob
