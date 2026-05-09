-- Create table for user-specific workspace furniture items
CREATE TABLE IF NOT EXISTS user_workspace_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    image_data TEXT NOT NULL, -- Base64 encoded image
    category VARCHAR(100) DEFAULT 'custom',
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    position_x DECIMAL(10, 2) DEFAULT 50.00,
    position_y DECIMAL(10, 2) DEFAULT 50.00,
    rotation_angle DECIMAL(10, 2) DEFAULT 0.00,
    scale_factor DECIMAL(10, 2) DEFAULT 1.00,
    z_index INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster user queries
CREATE INDEX idx_user_workspace_items_user_id ON user_workspace_items(user_id);
CREATE INDEX idx_user_workspace_items_active ON user_workspace_items(user_id, is_active);

-- Add comments
COMMENT ON TABLE user_workspace_items IS 'Stores user-specific furniture items for personalized workspace layouts';
COMMENT ON COLUMN user_workspace_items.image_data IS 'Base64 encoded PNG image data';
COMMENT ON COLUMN user_workspace_items.position_x IS 'X position as percentage (0-100)';
COMMENT ON COLUMN user_workspace_items.position_y IS 'Y position as percentage (0-100)';

-- Made with Bob
