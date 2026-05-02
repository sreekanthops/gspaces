-- Leads/Quotation Management System Database Schema

-- 1. Leads table (main customer/project)
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    project_name VARCHAR(255),
    reference_image VARCHAR(500), -- Main reference image
    status VARCHAR(50) DEFAULT 'draft', -- draft, sent, approved, rejected
    discount_type VARCHAR(20) DEFAULT 'none', -- none, percentage, fixed
    discount_value DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    share_token VARCHAR(100) UNIQUE, -- For shareable URL
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Lead designs (multiple designs per lead)
CREATE TABLE IF NOT EXISTS lead_designs (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) ON DELETE CASCADE,
    design_name VARCHAR(255) NOT NULL,
    design_image VARCHAR(500), -- Design-specific image
    design_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Design items (items/components for each design)
CREATE TABLE IF NOT EXISTS design_items (
    id SERIAL PRIMARY KEY,
    design_id INTEGER REFERENCES lead_designs(id) ON DELETE CASCADE,
    
    -- Table configuration
    table_enabled BOOLEAN DEFAULT FALSE,
    table_type VARCHAR(50), -- iron_legs, wooden_legs, u_shaped
    table_size VARCHAR(50), -- e.g., "4x2", "5x2"
    table_with_storage BOOLEAN DEFAULT FALSE,
    table_price DECIMAL(10,2) DEFAULT 0,
    
    -- Chair configuration
    chair_enabled BOOLEAN DEFAULT FALSE,
    chair_type VARCHAR(50), -- basic, basic_headrest, medium, high
    chair_quantity INTEGER DEFAULT 1,
    chair_price DECIMAL(10,2) DEFAULT 0,
    
    -- Plants
    mini_plants_enabled BOOLEAN DEFAULT FALSE,
    mini_plants_count INTEGER DEFAULT 0,
    mini_plants_price DECIMAL(10,2) DEFAULT 0,
    
    big_plants_enabled BOOLEAN DEFAULT FALSE,
    big_plants_count INTEGER DEFAULT 0,
    big_plants_price DECIMAL(10,2) DEFAULT 0,
    
    -- Artefacts
    artefacts_enabled BOOLEAN DEFAULT FALSE,
    artefacts_count INTEGER DEFAULT 0,
    artefacts_price DECIMAL(10,2) DEFAULT 0,
    
    -- Frames
    frames_enabled BOOLEAN DEFAULT FALSE,
    frames_mini_count INTEGER DEFAULT 0,
    frames_medium_count INTEGER DEFAULT 0,
    frames_large_count INTEGER DEFAULT 0,
    frames_price DECIMAL(10,2) DEFAULT 0,
    
    -- Table lamp
    table_lamp_enabled BOOLEAN DEFAULT FALSE,
    table_lamp_type VARCHAR(50), -- basic, medium, high
    table_lamp_price DECIMAL(10,2) DEFAULT 0,
    
    -- Accessories
    multisocket_enabled BOOLEAN DEFAULT FALSE,
    multisocket_price DECIMAL(10,2) DEFAULT 1200,
    
    cable_organiser_enabled BOOLEAN DEFAULT FALSE,
    cable_organiser_price DECIMAL(10,2) DEFAULT 1200,
    
    deskmat_enabled BOOLEAN DEFAULT FALSE,
    deskmat_price DECIMAL(10,2) DEFAULT 1000,
    
    floor_mat_enabled BOOLEAN DEFAULT FALSE,
    floor_mat_size VARCHAR(50), -- e.g., "2x4"
    floor_mat_price DECIMAL(10,2) DEFAULT 0,
    
    profile_light_enabled BOOLEAN DEFAULT FALSE,
    profile_light_feet DECIMAL(5,2) DEFAULT 0,
    profile_light_price DECIMAL(10,2) DEFAULT 0,
    
    clock_enabled BOOLEAN DEFAULT FALSE,
    clock_price DECIMAL(10,2) DEFAULT 1000,
    
    pegboard_enabled BOOLEAN DEFAULT FALSE,
    pegboard_size VARCHAR(50), -- e.g., "1x1", "2x2"
    pegboard_price DECIMAL(10,2) DEFAULT 0,
    
    -- Subtotal for this design
    subtotal DECIMAL(10,2) DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Custom fields (admin can add custom items)
CREATE TABLE IF NOT EXISTS design_custom_fields (
    id SERIAL PRIMARY KEY,
    design_id INTEGER REFERENCES lead_designs(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    field_value TEXT,
    field_price DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Pricing rules (for admin to manage base prices)
CREATE TABLE IF NOT EXISTS pricing_rules (
    id SERIAL PRIMARY KEY,
    item_category VARCHAR(100) NOT NULL, -- table, chair, plants, etc.
    item_type VARCHAR(100), -- iron_legs, wooden_legs, basic, medium, etc.
    base_price DECIMAL(10,2) NOT NULL,
    price_per_unit DECIMAL(10,2), -- For items priced per ft, per count, etc.
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default pricing rules
INSERT INTO pricing_rules (item_category, item_type, base_price, price_per_unit, description) VALUES
-- Tables
('table', 'iron_legs_4x2', 12000, 0, 'Iron legs table 4x2'),
('table', 'iron_legs_5x2', 18000, 0, 'Iron legs table 5x2'),
('table', 'wooden_legs_4x2', 15000, 0, 'Wooden legs U-shaped table 4x2'),
('table', 'storage_addon', 8000, 0, 'Storage addon for any table'),

-- Chairs
('chair', 'basic', 6000, 0, 'Basic chair'),
('chair', 'basic_headrest', 8000, 0, 'Basic chair with headrest'),
('chair', 'medium', 15000, 0, 'Medium range chair (10k-20k avg)'),
('chair', 'high', 25000, 0, 'High range chair (20k+ avg)'),

-- Plants
('plants', 'mini', 400, 400, 'Mini plant with pot'),
('plants', 'big', 1000, 1000, 'Big plant with pot'),

-- Artefacts
('artefacts', 'mini', 700, 700, 'Mini artefact'),

-- Frames
('frames', 'mini', 800, 800, 'Mini frame'),
('frames', 'medium', 1200, 1200, 'Medium frame'),
('frames', 'large', 2000, 2000, 'Large frame'),

-- Table lamps
('lamp', 'basic', 1000, 0, 'Basic table lamp'),
('lamp', 'medium', 2000, 0, 'Medium table lamp'),
('lamp', 'high', 3000, 0, 'High-end table lamp'),

-- Accessories
('accessory', 'multisocket', 1200, 0, 'Multisocket'),
('accessory', 'cable_organiser', 1200, 0, 'Cable organiser'),
('accessory', 'deskmat', 1000, 0, 'Desk mat'),
('accessory', 'floor_mat', 0, 500, 'Floor mat (per sq ft)'),
('accessory', 'profile_light', 0, 300, 'Profile light (per ft)'),
('accessory', 'clock', 1000, 0, 'Wall clock'),
('accessory', 'pegboard', 1000, 1000, 'Pegboard (per sq ft)')
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_leads_share_token ON leads(share_token);
CREATE INDEX IF NOT EXISTS idx_leads_created_by ON leads(created_by);
CREATE INDEX IF NOT EXISTS idx_lead_designs_lead_id ON lead_designs(lead_id);
CREATE INDEX IF NOT EXISTS idx_design_items_design_id ON design_items(design_id);
CREATE INDEX IF NOT EXISTS idx_custom_fields_design_id ON design_custom_fields(design_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_design_items_updated_at BEFORE UPDATE ON design_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Made with Bob
