-- Create table for animated furniture items on homepage banner
CREATE TABLE IF NOT EXISTS animated_furniture_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'chair', 'table', 'plant', 'lamp', 'decor', etc.
    width INTEGER NOT NULL DEFAULT 100, -- Width in pixels
    height INTEGER NOT NULL DEFAULT 100, -- Height in pixels
    initial_x DECIMAL(5,2) DEFAULT 50.0, -- Initial X position (percentage)
    initial_y DECIMAL(5,2) DEFAULT 50.0, -- Initial Y position (percentage)
    scatter_distance INTEGER DEFAULT 200, -- How far to scatter on load (pixels)
    rotation_angle INTEGER DEFAULT 0, -- Initial rotation angle
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX idx_animated_furniture_active ON animated_furniture_items(is_active, display_order);
CREATE INDEX idx_animated_furniture_category ON animated_furniture_items(category);

-- Create settings table for animation configuration
CREATE TABLE IF NOT EXISTS animated_banner_settings (
    id SERIAL PRIMARY KEY,
    is_enabled BOOLEAN DEFAULT true,
    scatter_duration INTEGER DEFAULT 2000, -- Animation duration in ms
    scatter_easing VARCHAR(50) DEFAULT 'ease-out',
    allow_drag BOOLEAN DEFAULT true,
    snap_to_grid BOOLEAN DEFAULT false,
    grid_size INTEGER DEFAULT 20,
    show_reset_button BOOLEAN DEFAULT true,
    background_color VARCHAR(20) DEFAULT '#f8f9fa',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO animated_banner_settings (id, is_enabled) 
VALUES (1, true)
ON CONFLICT (id) DO NOTHING;

-- Add some sample furniture items (you'll replace these with actual images)
INSERT INTO animated_furniture_items (name, image_path, category, width, height, initial_x, initial_y, display_order) VALUES
('Modern Chair', '/static/images/furniture/chair1.png', 'chair', 120, 140, 30, 50, 1),
('Office Desk', '/static/images/furniture/desk1.png', 'table', 200, 150, 50, 50, 2),
('Indoor Plant', '/static/images/furniture/plant1.png', 'plant', 80, 120, 70, 50, 3),
('Floor Lamp', '/static/images/furniture/lamp1.png', 'lamp', 60, 180, 20, 30, 4),
('Bookshelf', '/static/images/furniture/shelf1.png', 'storage', 150, 200, 80, 40, 5)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE animated_furniture_items IS 'Stores PNG furniture items for interactive homepage banner';
COMMENT ON TABLE animated_banner_settings IS 'Configuration settings for animated banner behavior';

-- Made with Bob
