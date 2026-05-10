-- Design Gallery Table
-- Stores design images with titles and descriptions for gallery display

CREATE TABLE IF NOT EXISTS design_gallery (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500) NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    category VARCHAR(100), -- e.g., 'office', 'home', 'commercial'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_design_gallery_active ON design_gallery(is_active);
CREATE INDEX IF NOT EXISTS idx_design_gallery_order ON design_gallery(display_order);
CREATE INDEX IF NOT EXISTS idx_design_gallery_category ON design_gallery(category);

-- Insert sample designs
INSERT INTO design_gallery (title, description, image_url, display_order, category) VALUES
    ('Modern Office Setup', 'Sleek and professional workspace design', '/static/img/designs/office1.jpg', 1, 'office'),
    ('Home Office Corner', 'Cozy home office with ergonomic furniture', '/static/img/designs/home1.jpg', 2, 'home'),
    ('Executive Suite', 'Luxury executive office design', '/static/img/designs/office2.jpg', 3, 'office'),
    ('Creative Studio', 'Inspiring creative workspace', '/static/img/designs/studio1.jpg', 4, 'commercial'),
    ('Minimalist Desk', 'Clean and simple desk setup', '/static/img/designs/minimal1.jpg', 5, 'home'),
    ('Conference Room', 'Professional meeting space', '/static/img/designs/conference1.jpg', 6, 'commercial')
ON CONFLICT DO NOTHING;

COMMENT ON TABLE design_gallery IS 'Design gallery images with hover text for users';
COMMENT ON COLUMN design_gallery.display_order IS 'Order in which designs appear in gallery';
COMMENT ON COLUMN design_gallery.category IS 'Design category for filtering';

-- Made with Bob
