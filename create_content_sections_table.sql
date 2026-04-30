-- Content Sections Table for Admin-Managed Page Content
-- This allows admins to upload images and manage content for different page sections

CREATE TABLE IF NOT EXISTS content_sections (
    id SERIAL PRIMARY KEY,
    page_name VARCHAR(50) NOT NULL,  -- 'about', 'corporate', 'team', 'contact'
    section_name VARCHAR(100) NOT NULL,  -- 'hero', 'mission', 'values', etc.
    title VARCHAR(255),
    subtitle TEXT,
    description TEXT,
    image_url VARCHAR(500),
    image_alt VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX idx_content_sections_page ON content_sections(page_name, is_active);
CREATE INDEX idx_content_sections_order ON content_sections(page_name, display_order);

-- Insert default content for About page
INSERT INTO content_sections (page_name, section_name, title, subtitle, description, image_url, display_order) VALUES
('about', 'hero', 'About GSpaces', 'Transforming Workspaces Across India', 'GSpaces is India''s leading provider of complete desk setup solutions.', '/static/img/about.jpg', 1),
('about', 'mission', 'Our Mission', NULL, 'To provide complete, ready-to-use desk setup solutions that combine functionality, aesthetics, and ergonomics.', NULL, 2),
('about', 'vision', 'Our Vision', NULL, 'To become India''s most trusted brand for workspace solutions.', NULL, 3);

-- Insert default content for Corporate page
INSERT INTO content_sections (page_name, section_name, title, subtitle, description, image_url, display_order) VALUES
('corporate', 'hero', 'Corporate Tie-ups', 'WFH Setup Solutions for IT Companies & Remote Teams', 'Partner with GSpaces to create organized, productive WFH environments.', '/static/img/services-1.jpg', 1),
('corporate', 'standardized', 'Standardized Setups', NULL, 'Provide every employee with a consistent, premium workspace — no more random setups.', '/static/img/services-1.jpg', 2),
('corporate', 'bulk_pricing', 'Bulk Pricing', NULL, 'Special corporate pricing for teams — better than individual reimbursements.', '/static/img/services-2.jpg', 3),
('corporate', 'end_to_end', 'End-to-End Setup', NULL, 'We handle delivery, installation & setup — completely hassle-free for your team.', '/static/img/services-3.jpg', 4);

-- Insert default content for Team page
INSERT INTO content_sections (page_name, section_name, title, subtitle, description, image_url, display_order) VALUES
('team', 'hero', 'Our Team', 'Meet the People Behind GSpaces', 'Dedicated professionals committed to transforming your workspace.', NULL, 1);

-- Insert default content for Contact page
INSERT INTO content_sections (page_name, section_name, title, subtitle, description, image_url, display_order) VALUES
('contact', 'hero', 'Contact Us', 'Get Your Free Consultation & Quote Today', 'We''re here to help you create your dream workspace.', NULL, 1);

COMMENT ON TABLE content_sections IS 'Stores admin-manageable content sections for different pages with image upload support';

-- Made with Bob
