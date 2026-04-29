-- AI Room Visualization System Database Schema
-- Stores user-generated room visualizations with AI

-- Create room_visualizations table
CREATE TABLE IF NOT EXISTS room_visualizations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    room_image_url VARCHAR(500) NOT NULL,
    result_image_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_user_visualizations (user_id, created_at DESC),
    INDEX idx_product_visualizations (product_id, created_at DESC)
);

-- Add comments
COMMENT ON TABLE room_visualizations IS 'Stores AI-generated room visualizations for products';
COMMENT ON COLUMN room_visualizations.user_id IS 'User who created the visualization';
COMMENT ON COLUMN room_visualizations.product_id IS 'Product being visualized';
COMMENT ON COLUMN room_visualizations.room_image_url IS 'Path to uploaded room image';
COMMENT ON COLUMN room_visualizations.result_image_url IS 'Path to AI-generated result image';

-- Create view for visualization statistics
CREATE OR REPLACE VIEW visualization_stats AS
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.category,
    COUNT(v.id) as total_visualizations,
    COUNT(DISTINCT v.user_id) as unique_users,
    MAX(v.created_at) as last_visualization
FROM products p
LEFT JOIN room_visualizations v ON p.id = v.product_id
GROUP BY p.id, p.name, p.category;

COMMENT ON VIEW visualization_stats IS 'Statistics about product visualizations';

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON room_visualizations TO gspaces_user;
GRANT USAGE, SELECT ON SEQUENCE room_visualizations_id_seq TO gspaces_user;
GRANT SELECT ON visualization_stats TO gspaces_user;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ AI Visualization tables created successfully!';
    RAISE NOTICE '📊 Tables: room_visualizations';
    RAISE NOTICE '📈 Views: visualization_stats';
END $$;

-- Made with Bob
