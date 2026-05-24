# Order Setup Button Feature - Implementation Guide

## Feature Overview
Add an admin "Order Setup" button on the products page that allows administrators to quickly create orders for customers without requiring payment processing. This streamlines the order creation process for walk-in customers, phone orders, or special arrangements.

## Feature Requirements

### 1. UI Components

#### Button Placement
- **Location**: Products page, next to Edit/Delete buttons for each setup/product
- **Visibility**: Admin users only
- **Style**: Consistent with existing admin action buttons
- **Icon**: Shopping cart or order icon
- **Label**: "Order Setup" or "Create Order"

#### Modal Dialog
- **Trigger**: Clicking the "Order Setup" button
- **Size**: Medium modal (responsive)
- **Close Options**: X button, Cancel button, click outside
- **Form Fields**:
  - Customer Name (required, text input)
  - Phone Number (required, tel input with validation)
  - Customer Type (required, dropdown):
    - Walk-in Customer
    - Phone Order
    - Referral
    - Repeat Customer
    - Corporate Client
  - Comments/Notes (optional, textarea)
  - Product/Setup Details (auto-populated from selected item)
  - Quantity (optional, number input, default: 1)
  - Special Instructions (optional, textarea)

### 2. Backend Functionality

#### Order Creation
- **Payment Status**: Mark as "Pending" or "Admin Created"
- **Payment Required**: No (bypass payment gateway)
- **Order Source**: Tag as "Admin Created"
- **Timestamp**: Record creation date/time
- **Created By**: Store admin user ID
- **Initial Status**: "Pending Confirmation" or "Processing"

#### Database Schema
```sql
-- Add to orders table or create new fields
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_source VARCHAR(50) DEFAULT 'customer';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_type VARCHAR(50);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS admin_created_by INTEGER REFERENCES users(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS requires_payment BOOLEAN DEFAULT true;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS admin_notes TEXT;
```

#### Order Data Structure
```python
{
    'customer_name': str,
    'customer_phone': str,
    'customer_type': str,
    'product_id': int,
    'product_name': str,
    'quantity': int,
    'comments': str,
    'order_source': 'admin_created',
    'requires_payment': False,
    'status': 'pending_confirmation',
    'created_by_admin': admin_user_id,
    'admin_notes': str,
    'created_at': datetime,
    'total_amount': decimal (if applicable)
}
```

### 3. Admin Orders Section

#### Display Requirements
- Show all orders including admin-created ones
- Filter options:
  - All Orders
  - Customer Orders (with payment)
  - Admin Created Orders (without payment)
  - By Status
  - By Customer Type
  - By Date Range
- Visual indicator for admin-created orders (badge/icon)
- Quick actions: View, Edit, Update Status, Delete

#### Order Details View
- Customer information
- Product/setup details
- Order source and creation method
- Admin who created the order
- Status history
- Comments and notes
- Contact information
- Action buttons: Update Status, Send Notification, Edit, Delete

### 4. Email Notifications

#### Notification Triggers
- Order Created (to customer)
- Status Updated (to customer)
- Order Completed (to customer)
- Order Cancelled (to customer)
- New Admin Order (to admin team - optional)

#### Email Templates

**Order Created Email**
```
Subject: Order Confirmation - [Order ID]

Dear [Customer Name],

Thank you for your order with GSpaces!

Order Details:
- Order ID: [Order ID]
- Product: [Product Name]
- Quantity: [Quantity]
- Status: [Status]

We will contact you shortly at [Phone Number] to confirm the details.

Comments: [Comments if any]

Best regards,
GSpaces Team
```

**Status Update Email**
```
Subject: Order Status Update - [Order ID]

Dear [Customer Name],

Your order status has been updated:

Order ID: [Order ID]
Previous Status: [Old Status]
New Status: [New Status]
Updated On: [Date/Time]

[Status-specific message]

For any questions, please contact us at [Contact Info].

Best regards,
GSpaces Team
```

#### Email Configuration
- Use existing email helper (`email_helper.py`)
- Queue emails for async sending
- Log all email notifications
- Handle failures gracefully
- Provide retry mechanism

### 5. Permissions & Security

#### Access Control
- Only admin users can see "Order Setup" button
- Verify admin permissions before order creation
- Log all admin-created orders for audit trail
- Validate all input data server-side

#### Validation Rules
- Customer name: 2-100 characters
- Phone number: Valid format (10-15 digits)
- Customer type: Must be from predefined list
- Product ID: Must exist in database
- Quantity: Positive integer

### 6. Implementation Steps

#### Phase 1: Database Setup
1. Create migration script for new columns
2. Update orders table schema
3. Add indexes for performance
4. Create backup before deployment

#### Phase 2: Backend Development
1. Create route handler for order creation
2. Implement validation logic
3. Add order creation function
4. Integrate with existing orders system
5. Add email notification triggers
6. Create admin order management endpoints

#### Phase 3: Frontend Development
1. Add "Order Setup" button to products page
2. Create modal component with form
3. Implement form validation
4. Add AJAX submission
5. Show success/error messages
6. Update admin orders page to display new orders

#### Phase 4: Email System
1. Create email templates
2. Implement notification logic
3. Add status update triggers
4. Test email delivery
5. Add email logging

#### Phase 5: Testing
1. Unit tests for order creation
2. Integration tests for email notifications
3. UI/UX testing
4. Permission testing
5. Edge case testing
6. Load testing

#### Phase 6: Deployment
1. Deploy database changes
2. Deploy backend code
3. Deploy frontend changes
4. Configure email settings
5. Monitor for issues
6. Document for team

### 7. File Structure

```
/templates/
  - admin_order_setup_modal.html (new)
  - admin_orders.html (update)
  - products.html (update)
  - email_order_created.html (new)
  - email_order_status_update.html (new)

/static/js/
  - admin_order_setup.js (new)

/routes/
  - admin_orders_routes.py (new or update existing)

/sql/
  - create_admin_order_setup.sql (new)

/docs/
  - ORDER_SETUP_DEPLOYMENT.md (new)
```

### 8. API Endpoints

```python
# Create admin order
POST /admin/orders/create-setup
Request Body: {
    'customer_name': str,
    'customer_phone': str,
    'customer_type': str,
    'product_id': int,
    'quantity': int,
    'comments': str
}
Response: {
    'success': bool,
    'order_id': int,
    'message': str
}

# Update order status
PUT /admin/orders/<order_id>/status
Request Body: {
    'status': str,
    'notes': str
}
Response: {
    'success': bool,
    'message': str
}

# Get admin orders
GET /admin/orders?filter=admin_created&status=pending
Response: {
    'orders': [...],
    'total': int,
    'page': int
}
```

### 9. Status Workflow

```
Admin Created → Pending Confirmation → Confirmed → In Progress → 
Ready for Delivery → Delivered → Completed

Alternative paths:
- Any status → Cancelled
- Any status → On Hold
```

### 10. Success Metrics

- Time to create order: < 30 seconds
- Email delivery rate: > 95%
- User satisfaction with feature
- Reduction in manual order entry errors
- Number of admin-created orders per day

### 11. Future Enhancements

- Bulk order creation
- Order templates for common setups
- SMS notifications
- Customer portal to view order status
- Integration with inventory system
- Automated follow-up reminders
- Payment link generation for later payment
- WhatsApp integration for notifications

### 12. Dependencies

- Existing orders system
- Email helper module
- Admin authentication system
- Products/setups database
- User permissions system

### 13. Rollback Plan

1. Keep backup of database before deployment
2. Feature flag to disable button if issues arise
3. Revert database changes if needed
4. Restore previous code version
5. Communicate with team about rollback

## Notes

- Ensure mobile responsiveness for modal
- Add loading states for better UX
- Implement proper error handling
- Log all actions for debugging
- Consider rate limiting for order creation
- Add confirmation dialog before order creation
- Provide clear feedback on success/failure

## Contact

For questions or clarifications about this feature, contact the development team.

---
**Document Version**: 1.0  
**Created**: 2026-05-24  
**Last Updated**: 2026-05-24  
**Status**: Ready for Implementation