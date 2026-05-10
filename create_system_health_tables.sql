-- System Health Monitoring Tables
-- This creates tables for tracking system logs, errors, and performance metrics

-- System Logs Table
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    log_level VARCHAR(20) NOT NULL, -- INFO, WARNING, ERROR, CRITICAL
    log_type VARCHAR(50) NOT NULL, -- REQUEST, DATABASE, AUTH, SYSTEM, etc.
    message TEXT NOT NULL,
    details JSONB, -- Additional structured data
    ip_address VARCHAR(45),
    user_id INTEGER REFERENCES users(id),
    route VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    response_time FLOAT, -- in milliseconds
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for system_logs
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON system_logs(log_level);
CREATE INDEX IF NOT EXISTS idx_system_logs_type ON system_logs(log_type);
CREATE INDEX IF NOT EXISTS idx_system_logs_created ON system_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_system_logs_user ON system_logs(user_id);

-- Error Logs Table (for detailed error tracking)
CREATE TABLE IF NOT EXISTS error_logs (
    id SERIAL PRIMARY KEY,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    route VARCHAR(255),
    method VARCHAR(10),
    user_id INTEGER REFERENCES users(id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id)
);

-- Create indexes for error_logs
CREATE INDEX IF NOT EXISTS idx_error_logs_type ON error_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_error_logs_created ON error_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved ON error_logs(resolved);

-- System Metrics Table (for performance tracking)
CREATE TABLE IF NOT EXISTS system_metrics (
    id SERIAL PRIMARY KEY,
    metric_type VARCHAR(50) NOT NULL, -- CPU, MEMORY, DISK, DATABASE, etc.
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    unit VARCHAR(20), -- %, MB, GB, ms, etc.
    details JSONB,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for system_metrics
CREATE INDEX IF NOT EXISTS idx_system_metrics_type ON system_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_system_metrics_recorded ON system_metrics(recorded_at);

-- API Request Logs (for tracking all API calls)
CREATE TABLE IF NOT EXISTS api_request_logs (
    id SERIAL PRIMARY KEY,
    route VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    response_time FLOAT, -- in milliseconds
    ip_address VARCHAR(45),
    user_id INTEGER REFERENCES users(id),
    user_agent TEXT,
    request_headers JSONB,
    request_body JSONB,
    response_size INTEGER, -- in bytes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for api_request_logs
CREATE INDEX IF NOT EXISTS idx_api_logs_route ON api_request_logs(route);
CREATE INDEX IF NOT EXISTS idx_api_logs_status ON api_request_logs(status_code);
CREATE INDEX IF NOT EXISTS idx_api_logs_created ON api_request_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_api_logs_user ON api_request_logs(user_id);

-- Create a function to automatically clean old logs
CREATE OR REPLACE FUNCTION clean_old_logs(days_to_keep INTEGER)
RETURNS TABLE(
    system_logs_deleted INTEGER,
    error_logs_deleted INTEGER,
    api_logs_deleted INTEGER,
    metrics_deleted INTEGER
) AS $$
DECLARE
    system_count INTEGER;
    error_count INTEGER;
    api_count INTEGER;
    metrics_count INTEGER;
BEGIN
    -- Delete old system logs
    DELETE FROM system_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS system_count = ROW_COUNT;
    
    -- Delete old resolved error logs
    DELETE FROM error_logs 
    WHERE resolved = TRUE 
    AND resolved_at < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS error_count = ROW_COUNT;
    
    -- Delete old API request logs
    DELETE FROM api_request_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS api_count = ROW_COUNT;
    
    -- Delete old system metrics
    DELETE FROM system_metrics 
    WHERE recorded_at < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS metrics_count = ROW_COUNT;
    
    RETURN QUERY SELECT system_count, error_count, api_count, metrics_count;
END;
$$ LANGUAGE plpgsql;

-- Insert some sample data for testing
INSERT INTO system_logs (log_level, log_type, message, route, method, status_code, response_time)
VALUES 
    ('INFO', 'REQUEST', 'User accessed homepage', '/', 'GET', 200, 45.2),
    ('INFO', 'AUTH', 'User logged in successfully', '/login', 'POST', 200, 120.5),
    ('WARNING', 'DATABASE', 'Slow query detected', '/admin/orders', 'GET', 200, 1500.0),
    ('ERROR', 'SYSTEM', 'Failed to send email notification', '/checkout', 'POST', 500, 250.0);

-- Add comments
COMMENT ON TABLE system_logs IS 'General system activity logs';
COMMENT ON TABLE error_logs IS 'Detailed error tracking and resolution';
COMMENT ON TABLE system_metrics IS 'System performance metrics over time';
COMMENT ON TABLE api_request_logs IS 'Detailed API request tracking';
COMMENT ON FUNCTION clean_old_logs IS 'Function to clean logs older than specified days';

-- Made with Bob
