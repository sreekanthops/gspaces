# Visitor Tracking & System Health Monitoring - Deployment Guide

## Overview
This system provides comprehensive visitor tracking and system health monitoring for your GSpaces website. It tracks all visitors, their behavior, and monitors system health with automatic email alerts for critical errors.

## Features

### 1. Visitor Tracking
- **Real-time visitor tracking** with unique visitor IDs
- **Geolocation tracking** (Country, City, Region)
- **Device information** (Browser, OS, Device Type)
- **Page view tracking** with time spent on each page
- **Session tracking** for user journey analysis
- **Referrer tracking** to understand traffic sources
- **User registration status** tracking

### 2. System Health Monitoring
- **Error logging** with severity levels (low, medium, high, critical)
- **Automatic email alerts** for critical errors
- **Health check API** for monitoring system status
- **Error details** with stack traces and request data
- **Response time tracking**

### 3. Admin Dashboards
- **Visitors Dashboard** - View all visitors with filters
- **System Health Dashboard** - Monitor errors and system status

## Installation Steps

### 1. Install Dependencies
```bash
pip3 install user-agents==2.2.0
```

### 2. Create Database Tables
```bash
sudo -u postgres psql -d gspaces -f create_visitor_tracking_system.sql
```

### 3. Configure Email Alerts
Set the following environment variables for email notifications:

```bash
export SMTP_SERVER='smtp.gmail.com'
export SMTP_PORT='587'
export SMTP_USERNAME='your-email@gmail.com'
export SMTP_PASSWORD='your-app-password'
export ADMIN_EMAIL='sreekanthchityala@gmail.com'
```

Add to your `.bashrc` or `.profile` for persistence:
```bash
echo "export ADMIN_EMAIL='sreekanthchityala@gmail.com'" >> ~/.bashrc
echo "export SMTP_USERNAME='your-email@gmail.com'" >> ~/.bashrc
echo "export SMTP_PASSWORD='your-app-password'" >> ~/.bashrc
source ~/.bashrc
```

### 4. Deploy Using Script
```bash
chmod +x deploy_visitor_tracking.sh
sudo ./deploy_visitor_tracking.sh
```

## Manual Deployment

If you prefer manual deployment:

1. **Backup your files:**
```bash
cp main.py main.py.backup_$(date +%Y%m%d)
cp templates/admin_nav.html templates/admin_nav.html.backup_$(date +%Y%m%d)
```

2. **Install Python packages:**
```bash
pip3 install user-agents==2.2.0
```

3. **Create database tables:**
```bash
sudo -u postgres psql -d gspaces -f create_visitor_tracking_system.sql
```

4. **Restart application:**
```bash
sudo systemctl restart gspaces
```

## Admin Panel Access

### Visitors Dashboard
- **URL:** `http://your-domain.com/admin/visitors`
- **Features:**
  - View all visitors with detailed information
  - Filter by date range, device type, country
  - See top pages and visitor statistics
  - View individual visitor details
  - Real-time updates (auto-refresh every 30 seconds)

### System Health Dashboard
- **URL:** `http://your-domain.com/admin/system-health`
- **Features:**
  - View all system errors
  - Filter by severity level
  - Run manual health checks
  - View error details with stack traces
  - Email notification status
  - Real-time updates (auto-refresh every 60 seconds)

## Database Schema

### visitor_tracking Table
Stores visitor information:
- `visitor_id` - Unique visitor identifier
- `ip_address` - Visitor's IP address
- `country`, `city`, `region` - Geolocation data
- `browser`, `os`, `device_type` - Device information
- `first_visit`, `last_visit` - Visit timestamps
- `total_visits`, `total_page_views` - Activity metrics
- `is_registered`, `user_id` - Registration status

### page_views Table
Tracks individual page views:
- `visitor_id` - Links to visitor_tracking
- `page_url`, `page_title` - Page information
- `time_spent` - Time spent on page (seconds)
- `session_id` - Session identifier
- `created_at` - View timestamp

### error_alerts Table
Logs system errors:
- `error_type` - Type of error
- `error_message` - Error description
- `stack_trace` - Full stack trace
- `endpoint` - Where error occurred
- `severity` - Error severity level
- `is_notified` - Email sent status

### system_health_logs Table
Stores health check results:
- `check_type` - Type of health check
- `status` - OK or FAILED
- `response_time` - Check duration
- `endpoint` - Checked endpoint

## API Endpoints

### Track Visitor (Frontend)
```javascript
POST /api/visitor/track
{
  "page_url": "/products",
  "page_title": "Products",
  "time_spent": 45
}
```

### Health Check
```bash
GET /api/system/health-check
```

### Visitor Details
```bash
GET /api/visitor/{visitor_id}/details
```

### Error Details
```bash
GET /api/error/{error_id}/details
```

## Email Alert Configuration

### Gmail Setup
1. Enable 2-Factor Authentication in your Google Account
2. Generate an App Password:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. Use the generated password as `SMTP_PASSWORD`

### Email Alert Triggers
Emails are sent automatically for:
- **Critical errors** - Immediate notification
- **High priority errors** - Immediate notification
- **System failures** - Database, API failures

### Email Content
Alerts include:
- Error ID and type
- Endpoint where error occurred
- Full error message
- Timestamp
- Link to system health dashboard

## Monitoring Best Practices

### 1. Regular Checks
- Check System Health dashboard daily
- Review visitor patterns weekly
- Monitor error trends

### 2. Performance Optimization
- Archive old visitor data (>90 days)
- Clean up resolved errors
- Monitor database size

### 3. Security
- Regularly review visitor IPs for suspicious activity
- Monitor failed login attempts
- Check for unusual traffic patterns

## Troubleshooting

### Visitors Not Being Tracked
1. Check if visitor_tracking_routes.py is imported in main.py
2. Verify database tables exist
3. Check application logs for errors

### Email Alerts Not Sending
1. Verify SMTP credentials are set
2. Check ADMIN_EMAIL is configured
3. Test SMTP connection manually
4. Check application logs for email errors

### Database Connection Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test database connection
sudo -u postgres psql -d gspaces -c "SELECT 1;"
```

### High Database Load
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Archive old data
DELETE FROM page_views WHERE created_at < NOW() - INTERVAL '90 days';
DELETE FROM error_alerts WHERE created_at < NOW() - INTERVAL '30 days' AND is_notified = TRUE;
```

## Maintenance

### Weekly Tasks
- Review error logs
- Check visitor statistics
- Verify email alerts are working

### Monthly Tasks
- Archive old visitor data
- Clean up resolved errors
- Review system performance

### Quarterly Tasks
- Analyze visitor trends
- Update geolocation database
- Review and optimize queries

## Support

For issues or questions:
- Check application logs: `/var/log/gspaces/`
- Review error dashboard: `/admin/system-health`
- Contact: sreekanthchityala@gmail.com

## Version History

### v1.0.0 (2026-05-09)
- Initial release
- Visitor tracking with geolocation
- System health monitoring
- Email alerts for critical errors
- Admin dashboards

## Future Enhancements

Planned features:
- Real-time visitor map
- Advanced analytics and reports
- Custom alert rules
- Integration with monitoring tools (Grafana, Prometheus)
- Mobile app for monitoring
- Visitor behavior heatmaps
- A/B testing integration