-- Deals Management System Schema
-- This creates tables for managing category-level discounts and deal campaigns

-- Table for storing deal campaigns
CREATE TABLE IF NOT EXISTS deal_campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    start_time DATETIME,
    end_time DATETIME,
    countdown_duration INT DEFAULT 0 COMMENT 'Duration in seconds',
    banner_text VARCHAR(500) DEFAULT 'Limited Time Offer - Save Big Today!',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (is_active),
    INDEX idx_dates (start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for category-level discounts
CREATE TABLE IF NOT EXISTS category_discounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id INT,
    category_id INT,
    category_name VARCHAR(255) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Discount percentage (0-100)',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (campaign_id) REFERENCES deal_campaigns(id) ON DELETE CASCADE,
    INDEX idx_campaign (campaign_id),
    INDEX idx_category (category_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for global discount (applies to all products)
CREATE TABLE IF NOT EXISTS global_discount (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id INT,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Global discount percentage (0-100)',
    is_active BOOLEAN DEFAULT FALSE,
    priority INT DEFAULT 0 COMMENT 'Higher priority overrides category discounts',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (campaign_id) REFERENCES deal_campaigns(id) ON DELETE CASCADE,
    INDEX idx_campaign (campaign_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default campaign for immediate use
INSERT INTO deal_campaigns (name, description, is_active, banner_text, countdown_duration)
VALUES (
    'Welcome Offer',
    'Default campaign for new visitors',
    TRUE,
    'Limited Time Offer - Exclusive Discounts on Premium Desk Setups',
    86400
) ON DUPLICATE KEY UPDATE name=name;

-- Insert default global discount (5% for visitor attention)
INSERT INTO global_discount (campaign_id, discount_percent, is_active, priority)
SELECT id, 5.00, TRUE, 1
FROM deal_campaigns
WHERE name = 'Welcome Offer'
LIMIT 1
ON DUPLICATE KEY UPDATE discount_percent=discount_percent;

-- Add discount tracking columns to products table if they don't exist
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2) DEFAULT NULL COMMENT 'Original price before discount',
ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Current discount percentage',
ADD COLUMN IF NOT EXISTS discounted_price DECIMAL(10,2) DEFAULT NULL COMMENT 'Price after discount';

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

-- Made with Bob
