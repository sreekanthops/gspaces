-- Team Members Table for Admin Management
CREATE TABLE IF NOT EXISTS team_members (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    bio TEXT,
    image_url VARCHAR(500),
    email VARCHAR(255),
    linkedin_url VARCHAR(500),
    twitter_url VARCHAR(500),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_team_members_active ON team_members(is_active, display_order);

-- Insert default team members (update with real data)
INSERT INTO team_members (name, role, bio, image_url, display_order) VALUES
('Team Member 1', 'Founder & CEO', 'Passionate about transforming workspaces', '/static/img/team/team-1.jpg', 1),
('Team Member 2', 'Head of Design', 'Creating beautiful and functional spaces', '/static/img/team/team-2.jpg', 2),
('Team Member 3', 'Operations Manager', 'Ensuring smooth delivery and installation', '/static/img/team/team-3.jpg', 3);

COMMENT ON TABLE team_members IS 'Stores team member information with admin management support';

-- Made with Bob
