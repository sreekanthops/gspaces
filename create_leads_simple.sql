-- Simplified Leads/Quotation System for MVP

-- 1. Leads table (customer/project)
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    project_name VARCHAR(255),
    reference_image VARCHAR(500), -- Main reference image
    notes TEXT,
    share_token VARCHAR(100) UNIQUE,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Design options (multiple designs per lead)
CREATE TABLE IF NOT EXISTS lead_designs (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) ON DELETE CASCADE,
    design_name VARCHAR(255) NOT NULL,
    design_image VARCHAR(500),
    
    -- Simple checkboxes for items
    has_table BOOLEAN DEFAULT FALSE,
    has_chair BOOLEAN DEFAULT FALSE,
    has_plants BOOLEAN DEFAULT FALSE,
    has_lighting BOOLEAN DEFAULT FALSE,
    has_storage BOOLEAN DEFAULT FALSE,
    has_accessories BOOLEAN DEFAULT FALSE,
    
    -- Item details (simple text)
    table_details TEXT,
    chair_details TEXT,
    plants_details TEXT,
    lighting_details TEXT,
    storage_details TEXT,
    accessories_details TEXT,
    
    -- Manual price set by admin
    price DECIMAL(10,2) DEFAULT 0,
    
    notes TEXT,
    design_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_leads_share_token ON leads(share_token);
CREATE INDEX IF NOT EXISTS idx_lead_designs_lead_id ON lead_designs(lead_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_leads_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_leads_updated_at 
    BEFORE UPDATE ON leads
    FOR EACH ROW 
    EXECUTE FUNCTION update_leads_timestamp();

-- Made with Bob
