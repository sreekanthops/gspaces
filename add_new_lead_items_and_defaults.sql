-- Add new item fields and default prices to lead_designs table
-- This adds: Desk Lamp, Pen Holder, Laptop Holder, and Chair Headrest option

-- Add Desk Lamp columns
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS has_desk_lamp BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS desk_lamp_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_lamp_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS desk_lamp_details TEXT;

-- Add Pen Holder columns
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS has_pen_holder BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS pen_holder_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS pen_holder_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS pen_holder_details TEXT;

-- Add Laptop Holder columns
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS has_laptop_holder BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS laptop_holder_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS laptop_holder_price DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS laptop_holder_details TEXT;

-- Add Chair Headrest option
ALTER TABLE lead_designs 
ADD COLUMN IF NOT EXISTS chair_headrest VARCHAR(20) DEFAULT 'with_headrest';
-- Options: 'with_headrest', 'without_headrest'

-- Create default prices table
CREATE TABLE IF NOT EXISTS item_default_prices (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) UNIQUE NOT NULL,
    default_price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default prices for all items
INSERT INTO item_default_prices (item_name, default_price, description) VALUES
('table', 15000.00, 'Desk Table - Standard ergonomic desk'),
('chair', 12000.00, 'Office Chair - Ergonomic with lumbar support'),
('lighting', 3000.00, 'Lighting - LED desk/ambient lighting'),
('storage', 8000.00, 'Storage - Cabinets, drawers, shelves'),
('accessories', 2000.00, 'Accessories - Desk organizers, pen holders, etc'),
('carpet', 5000.00, 'Carpet - Floor mat/carpet'),
('curtains', 4000.00, 'Curtains - Window curtains'),
('wall_art', 3000.00, 'Wall Art - Frames, paintings, posters'),
('desk_organizer', 1500.00, 'Desk Organizer - Desktop organization'),
('monitor_stand', 2500.00, 'Monitor Stand - Adjustable monitor riser'),
('cable_management', 800.00, 'Cable Management - Cable organizers and clips'),
('desk_mat', 1200.00, 'Desk Mat - Large desk pad/mat'),
('footrest', 1500.00, 'Footrest - Ergonomic footrest'),
('keyboard', 3500.00, 'Keyboard - Mechanical/wireless keyboard'),
('mouse', 1500.00, 'Mouse - Wireless/ergonomic mouse'),
('monitor', 15000.00, 'Monitor - LED/LCD display monitor'),
('laptop_stand', 2000.00, 'Laptop Stand - Adjustable laptop riser'),
('headphone_stand', 800.00, 'Headphone Stand - Desktop headphone holder'),
('whiteboard', 3500.00, 'Whiteboard - Wall-mounted whiteboard'),
('bookshelf', 10000.00, 'Bookshelf - Wall/floor bookshelf'),
('trash_bin', 500.00, 'Trash Bin - Desktop/floor waste bin'),
('desk_lamp', 2500.00, 'Desk Lamp - LED desk lamp'),
('pen_holder', 500.00, 'Pen Holder - Desktop pen/pencil holder'),
('laptop_holder', 1800.00, 'Laptop Holder - Vertical laptop stand')
ON CONFLICT (item_name) DO UPDATE SET
    default_price = EXCLUDED.default_price,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- Verify the new columns
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'lead_designs' 
AND (column_name LIKE '%desk_lamp%' 
   OR column_name LIKE '%pen_holder%'
   OR column_name LIKE '%laptop_holder%'
   OR column_name LIKE '%chair_headrest%')
ORDER BY column_name;

-- Verify default prices table
SELECT * FROM item_default_prices ORDER BY item_name;

-- Made with Bob
