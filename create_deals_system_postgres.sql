-- Deals Management System Schema for PostgreSQL
-- This creates tables for managing category-level discounts and deal campaigns

-- Table for storing deal campaigns
CREATE TABLE IF NOT EXISTS deal_campaigns (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    countdown_duration INTEGER DEFAULT 0, -- Duration in seconds
    banner_text VARCHAR(500) DEFAULT 'Limited Time Offer - Save Big Today!',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_campaigns_active ON deal_campaigns(is_active);
CREATE INDEX IF NOT EXISTS idx_campaigns_dates ON deal_campaigns(start_time, end_time);

-- Table for category-level discounts
CREATE TABLE IF NOT EXISTS category_discounts (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES deal_campaigns(id) ON DELETE CASCADE,
    category_id INTEGER,
    category_name VARCHAR(255) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Discount percentage (0-100)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_category_discounts_campaign ON category_discounts(campaign_id);
CREATE INDEX IF NOT EXISTS idx_category_discounts_category ON category_discounts(category_id);
CREATE INDEX IF NOT EXISTS idx_category_discounts_active ON category_discounts(is_active);

-- Table for global discount (applies to all products)
CREATE TABLE IF NOT EXISTS global_discount (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES deal_campaigns(id) ON DELETE CASCADE,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Global discount percentage (0-100)
    is_active BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 0, -- Higher priority overrides category discounts
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_global_discount_campaign ON global_discount(campaign_id);
CREATE INDEX IF NOT EXISTS idx_global_discount_active ON global_discount(is_active);

-- Insert default campaign for immediate use
INSERT INTO deal_campaigns (name, description, is_active, banner_text, countdown_duration)
VALUES (
    'Welcome Offer',
    'Default campaign for new visitors',
    TRUE,
    'Limited Time Offer - Exclusive Discounts on Premium Desk Setups',
    86400
)
ON CONFLICT DO NOTHING;

-- Insert default global discount (5% for visitor attention)
INSERT INTO global_discount (campaign_id, discount_percent, is_active, priority)
SELECT id, 5.00, TRUE, 1
FROM deal_campaigns
WHERE name = 'Welcome Offer'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Add discount tracking columns to products table if they don't exist
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS discounted_price DECIMAL(10,2) DEFAULT NULL;

-- Create view for active deals with category discounts
CREATE OR REPLACE VIEW active_deals_view AS
SELECT 
    dc.id as campaign_id,
    dc.name as campaign_name,
    dc.banner_text,
    dc.end_time,
    dc.countdown_duration,
    cd.category_id,
    cd.category_name,
    cd.discount_percent as category_discount,
    gd.discount_percent as global_discount,
    gd.priority as global_priority,
    CASE 
        WHEN gd.is_active = TRUE AND gd.priority > 0 THEN gd.discount_percent
        ELSE cd.discount_percent
    END as effective_discount
FROM deal_campaigns dc
LEFT JOIN category_discounts cd ON dc.id = cd.campaign_id AND cd.is_active = TRUE
LEFT JOIN global_discount gd ON dc.id = gd.campaign_id AND gd.is_active = TRUE
WHERE dc.is_active = TRUE
AND (dc.end_time IS NULL OR dc.end_time > NOW());

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_deal_campaigns_updated_at ON deal_campaigns;
CREATE TRIGGER update_deal_campaigns_updated_at BEFORE UPDATE ON deal_campaigns
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_category_discounts_updated_at ON category_discounts;
CREATE TRIGGER update_category_discounts_updated_at BEFORE UPDATE ON category_discounts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_global_discount_updated_at ON global_discount;
CREATE TRIGGER update_global_discount_updated_at BEFORE UPDATE ON global_discount
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Made with Bob
