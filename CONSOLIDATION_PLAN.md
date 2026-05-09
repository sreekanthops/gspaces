# Admin Panel Consolidation & Enhanced Health Monitoring Plan

## Phase 1: Sidebar Consolidation

### Current Structure:
- Coupons (separate)
- Referral Coupons (separate)
- Deals (separate)
- Customers (separate)
- Manage Users (separate)

### New Structure:
1. **Deals & Promotions** (merged section with tabs)
   - Coupons tab
   - Referral Coupons tab
   - Deals tab

2. **Users Management** (merged section with tabs)
   - Customers tab
   - Admin Users tab

## Phase 2: Enhanced Health Monitoring

### Current: Basic error logging
### New: Comprehensive health checks

1. **Page Health Checks**
   - Test all public pages (/, /products, /about, /contact, etc.)
   - Check response codes (200, 404, 500)
   - Measure response times
   - Verify page loads correctly

2. **Functionality Checks**
   - Contact form submission
   - Email sending capability
   - Database connectivity
   - File upload functionality
   - Payment gateway connectivity

3. **Contact Button Checks**
   - WhatsApp button functionality
   - Email button functionality
   - Phone button functionality

4. **Email System Checks**
   - SMTP connection test
   - Test email sending
   - Verify email templates load

## Implementation Steps:

1. Create new consolidated templates:
   - admin_deals_promotions.html (with tabs for coupons, referral, deals)
   - admin_users_management.html (with tabs for customers, admin users)

2. Update admin_sidebar.html to merge sections

3. Enhance visitor_tracking_routes.py with comprehensive health checks

4. Create health check functions for:
   - All pages
   - Contact forms
   - Email system
   - Database
   - External services

5. Update system health dashboard to show all checks

## No Impact Guarantee:
- All existing routes remain functional
- Old URLs still work (redirects if needed)
- No database schema changes
- Backward compatible