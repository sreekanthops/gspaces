-- Create visitor tracking table
CREATE TABLE IF NOT EXISTS visitor_tracking (
    id SERIAL PRIMARY KEY,
    visitor_id VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    country VARCHAR(100),
    city VARCHAR(100),
    region VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    device_type VARCHAR(50),
    referrer TEXT,
    landing_page TEXT,
    first_visit TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_visit TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_visits INTEGER DEFAULT 1,
    total_page_views INTEGER DEFAULT 1,
    is_registered BOOLEAN DEFAULT FALSE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create page views table
CREATE TABLE IF NOT EXISTS page_views (
    id SERIAL PRIMARY KEY,
    visitor_id VARCHAR(255) NOT NULL,
    page_url TEXT NOT NULL,
    page_title VARCHAR(500),
    referrer TEXT,
    time_spent INTEGER DEFAULT 0,
    session_id VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visitor_id) REFERENCES visitor_tracking(visitor_id) ON DELETE CASCADE
);

-- Create system health monitoring table
CREATE TABLE IF NOT EXISTS system_health_logs (
    id SERIAL PRIMARY KEY,
    check_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    error_message TEXT,
    response_time INTEGER,
    endpoint VARCHAR(500),
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create error alerts table
CREATE TABLE IF NOT EXISTS error_alerts (
    id SERIAL PRIMARY KEY,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    endpoint VARCHAR(500),
    request_data JSONB,
    user_id INTEGER,
    ip_address VARCHAR(45),
    severity VARCHAR(20) DEFAULT 'medium',
    is_notified BOOLEAN DEFAULT FALSE,
    notification_sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_visitor_tracking_visitor_id ON visitor_tracking(visitor_id);
CREATE INDEX IF NOT EXISTS idx_visitor_tracking_ip ON visitor_tracking(ip_address);
CREATE INDEX IF NOT EXISTS idx_visitor_tracking_last_visit ON visitor_tracking(last_visit);
CREATE INDEX IF NOT EXISTS idx_page_views_visitor_id ON page_views(visitor_id);
CREATE INDEX IF NOT EXISTS idx_page_views_created_at ON page_views(created_at);
CREATE INDEX IF NOT EXISTS idx_page_views_session_id ON page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_system_health_created_at ON system_health_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_system_health_status ON system_health_logs(status);
CREATE INDEX IF NOT EXISTS idx_error_alerts_created_at ON error_alerts(created_at);
CREATE INDEX IF NOT EXISTS idx_error_alerts_is_notified ON error_alerts(is_notified);
CREATE INDEX IF NOT EXISTS idx_error_alerts_severity ON error_alerts(severity);

-- Insert sample data for testing
INSERT INTO visitor_tracking (visitor_id, ip_address, country, city, browser, os, device_type, landing_page)
VALUES 
    ('visitor_' || md5(random()::text), '192.168.1.1', 'India', 'Mumbai', 'Chrome', 'Windows', 'Desktop', '/'),
    ('visitor_' || md5(random()::text), '192.168.1.2', 'India', 'Delhi', 'Safari', 'iOS', 'Mobile', '/products')
ON CONFLICT (visitor_id) DO NOTHING;

-- Made with Bob
