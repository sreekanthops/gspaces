-- Create homepage_banner table for admin-controlled banner management
CREATE TABLE IF NOT EXISTS homepage_banner (
    id SERIAL PRIMARY KEY,
    banner_image VARCHAR(500) NOT NULL,
    title VARCHAR(200) DEFAULT 'Premium Home Office Setup',
    subtitle TEXT DEFAULT 'Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.',
    button_text VARCHAR(100) DEFAULT 'Get Started',
    button_link VARCHAR(200) DEFAULT '/products',
    video_link VARCHAR(300) DEFAULT 'https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default banner
INSERT INTO homepage_banner (banner_image, title, subtitle, button_text, button_link, video_link, is_active)
VALUES (
    '/static/img/hero-bg.jpg',
    'Premium Home Office Setup',
    'Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.',
    'Get Started',
    '/products',
    'https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81',
    TRUE
)
ON CONFLICT DO NOTHING;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_homepage_banner_active ON homepage_banner(is_active);

-- Made with Bob
