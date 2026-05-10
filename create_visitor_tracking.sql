-- Create visitor tracking table
CREATE TABLE IF NOT EXISTS visitor_tracking (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    browser VARCHAR(100),
    device_type VARCHAR(50),
    os VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    referrer TEXT,
    landing_page TEXT,
    current_page TEXT,
    page_title VARCHAR(500),
    visit_duration INTEGER DEFAULT 0,
    pages_viewed INTEGER DEFAULT 1,
    is_bot BOOLEAN DEFAULT FALSE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create page views table for detailed tracking
CREATE TABLE IF NOT EXISTS page_views (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    visitor_id INTEGER REFERENCES visitor_tracking(id) ON DELETE CASCADE,
    page_url TEXT NOT NULL,
    page_title VARCHAR(500),
    time_spent INTEGER DEFAULT 0,
    scroll_depth INTEGER DEFAULT 0,
    interactions JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create visitor events table for tracking specific actions
CREATE TABLE IF NOT EXISTS visitor_events (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    visitor_id INTEGER REFERENCES visitor_tracking(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}',
    page_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_visitor_session ON visitor_tracking(session_id);
CREATE INDEX IF NOT EXISTS idx_visitor_ip ON visitor_tracking(ip_address);
CREATE INDEX IF NOT EXISTS idx_visitor_created ON visitor_tracking(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_visitor_user ON visitor_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_pageview_session ON page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_pageview_visitor ON page_views(visitor_id);
CREATE INDEX IF NOT EXISTS idx_pageview_created ON page_views(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_event_session ON visitor_events(session_id);
CREATE INDEX IF NOT EXISTS idx_event_visitor ON visitor_events(visitor_id);
CREATE INDEX IF NOT EXISTS idx_event_type ON visitor_events(event_type);
CREATE INDEX IF NOT EXISTS idx_event_created ON visitor_events(created_at DESC);

-- Create view for visitor analytics
CREATE OR REPLACE VIEW visitor_analytics AS
SELECT 
    DATE(vt.created_at) as visit_date,
    COUNT(DISTINCT vt.session_id) as unique_visitors,
    COUNT(DISTINCT vt.ip_address) as unique_ips,
    SUM(vt.pages_viewed) as total_page_views,
    AVG(vt.visit_duration) as avg_duration,
    COUNT(CASE WHEN vt.user_id IS NOT NULL THEN 1 END) as logged_in_visitors,
    COUNT(CASE WHEN vt.is_bot = TRUE THEN 1 END) as bot_visits
FROM visitor_tracking vt
GROUP BY DATE(vt.created_at)
ORDER BY visit_date DESC;

-- Create view for popular pages
CREATE OR REPLACE VIEW popular_pages AS
SELECT 
    pv.page_url,
    pv.page_title,
    COUNT(*) as view_count,
    AVG(pv.time_spent) as avg_time_spent,
    AVG(pv.scroll_depth) as avg_scroll_depth
FROM page_views pv
WHERE pv.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY pv.page_url, pv.page_title
ORDER BY view_count DESC
LIMIT 50;

-- Create view for traffic sources
CREATE OR REPLACE VIEW traffic_sources AS
SELECT 
    CASE 
        WHEN vt.referrer IS NULL OR vt.referrer = '' THEN 'Direct'
        WHEN vt.referrer LIKE '%google%' THEN 'Google'
        WHEN vt.referrer LIKE '%facebook%' THEN 'Facebook'
        WHEN vt.referrer LIKE '%instagram%' THEN 'Instagram'
        WHEN vt.referrer LIKE '%twitter%' OR vt.referrer LIKE '%x.com%' THEN 'Twitter/X'
        WHEN vt.referrer LIKE '%linkedin%' THEN 'LinkedIn'
        ELSE 'Other'
    END as source,
    COUNT(DISTINCT vt.session_id) as visitor_count,
    AVG(vt.pages_viewed) as avg_pages_viewed,
    AVG(vt.visit_duration) as avg_duration
FROM visitor_tracking vt
WHERE vt.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY source
ORDER BY visitor_count DESC;

COMMENT ON TABLE visitor_tracking IS 'Tracks visitor sessions and basic information';
COMMENT ON TABLE page_views IS 'Tracks individual page views within sessions';
COMMENT ON TABLE visitor_events IS 'Tracks specific user interactions and events';

-- Made with Bob
