# Order Setup Feature Enhancement Plan

## 📋 Current Issues & Improvements Needed

### 1. Email Not Sending
**Problem:** Emails are not being received by customers
**Possible Causes:**
- SMTP credentials not configured in environment
- Email helper function not being called properly
- Email going to spam folder

**Solution:**
- Verify SMTP_PASSWORD environment variable is set
- Check email logs
- Improve email template with professional design

### 2. Email Template Enhancement
**Requirements:**
- Professional design matching existing order confirmation emails
- Include product image
- Show order details: Order ID, Product Name, Quantity
- Display pricing: Original Price, Discount %, Final Price
- Customer information
- Company branding
- Call-to-action buttons

### 3. Feature Location Change
**Current:** Order Setup button on Products page
**Proposed:** Move to Quotation page

**Rationale:**
- Quotation already has all customer details (name, phone, email, address)
- Has complete design information (items, measurements, specifications)
- Shows pricing breakdown (total, discounts, final price)
- More logical workflow: Quotation → Order
- Reduces data entry (auto-fill from quotation)

## 🎯 New Implementation Plan

### Phase 1: Move Feature to Quotation Page

#### A. Remove from Products Page
- Remove "Order Setup" button from products.html
- Keep modal template for reuse

#### B. Add to Quotation Page
**Location:** Below final price section, before feedback section
**Button:** "Create Order" (Admin only, visible when viewing quotation)

**Button Features:**
- Only visible to admin users
- Prominent placement near final price
- Opens modal with pre-filled data from quotation

#### C. Modal Pre-fill Logic
Auto-populate from quotation:
- Customer Name: `lead.customer_name`
- Phone: `lead.customer_phone`
- Email: `lead.customer_email`
- Address: `lead.customer_address`
- Design Name: `lead.design_name`
- Total Amount: `lead.total_price`
- Items: All items from quotation with quantities
- Measurements: If available
- Customer Type: Default to appropriate type

**Editable Fields:**
- Discount percentage (calculate final price)
- Final price (manual override)
- Customer type
- Additional notes
- Payment terms

### Phase 2: Enhanced Email Template

#### Professional Email Design
```
┌─────────────────────────────────────────┐
│  [GSPACES LOGO]                         │
│  Order Confirmation                     │
├─────────────────────────────────────────┤
│                                         │
│  Hi [Customer Name],                    │
│                                         │
│  Thank you for your order!              │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ [PRODUCT IMAGE]                   │ │
│  │                                   │ │
│  │ Order #12345                      │ │
│  │ [Design Name]                     │ │
│  │                                   │ │
│  │ Quantity: 1                       │ │
│  │ Original Price: ₹30,000           │ │
│  │ Discount: 10% (₹3,000)            │ │
│  │ ─────────────────────────────     │ │
│  │ Final Price: ₹27,000              │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Order Details:                         │
│  • Items: [List of items]              │
│  • Measurements: [If available]        │
│  • Delivery: [Estimated date]          │
│                                         │
│  [View Order Details Button]            │
│  [Contact Us Button]                    │
│                                         │
│  Questions? Reply to this email         │
│                                         │
├─────────────────────────────────────────┤
│  © 2026 GSpaces                         │
│  Transform Your Space                   │
└─────────────────────────────────────────┘
```

#### Email Template Features
- Responsive design (mobile-friendly)
- Product image from quotation/design
- Clear pricing breakdown
- Professional branding
- Action buttons
- Contact information
- Order tracking link (future)

### Phase 3: Database Schema Updates

#### New Fields for Orders Table
```sql
ALTER TABLE orders ADD COLUMN IF NOT EXISTS:
- quotation_id INTEGER REFERENCES leads(id)
- design_name VARCHAR(255)
- original_price NUMERIC(10,2)
- discount_percentage NUMERIC(5,2)
- discount_amount NUMERIC(10,2)
- items_json JSONB  -- Store all items from quotation
- measurements_json JSONB  -- Store measurements
```

#### Link Orders to Quotations
- Track which quotation generated the order
- Maintain quotation history
- Enable order-to-quotation reference

### Phase 4: Backend Updates

#### New Route: Create Order from Quotation
```python
@app.route('/quotation/<share_token>/create-order', methods=['POST'])
@login_required
def create_order_from_quotation(share_token):
    # Get quotation details
    # Pre-fill order data
    # Allow price/discount override
    # Create order
    # Send professional email
    # Update quotation status
    # Return success
```

#### Email Function Enhancement
```python
def send_professional_order_email(order_data):
    # Get product image
    # Calculate pricing breakdown
    # Render professional template
    # Send email with retry logic
    # Log email status
```

### Phase 5: UI/UX Improvements

#### Quotation Page Updates
1. Add "Create Order" button section
2. Style to match quotation design
3. Show order status if already created
4. Disable button if order exists

#### Modal Enhancements
1. Show quotation summary
2. Editable pricing section
3. Discount calculator
4. Preview final email
5. Confirmation step

#### Admin Orders Page
1. Show linked quotation
2. Link back to quotation
3. Display discount information
4. Show original vs final price

## 📊 Data Flow

```
Quotation Created
    ↓
Admin Reviews Quotation
    ↓
Admin Clicks "Create Order"
    ↓
Modal Opens (Pre-filled)
    ↓
Admin Adjusts Price/Discount (Optional)
    ↓
Admin Confirms Order
    ↓
Order Created in Database
    ↓
Professional Email Sent
    ↓
Order Appears in Admin Orders
    ↓
Customer Receives Email
    ↓
Order Tracking & Updates
```

## 🎨 Email Template Specifications

### Colors
- Primary: #667eea (Purple)
- Secondary: #764ba2 (Dark Purple)
- Success: #10b981 (Green)
- Text: #111827 (Dark Gray)
- Background: #f8fafc (Light Gray)

### Typography
- Headings: Bold, 24-28px
- Body: Regular, 16px
- Price: Bold, 20-24px
- Discount: Medium, 18px, Green

### Images
- Product image: 400x300px, centered
- Logo: 150px width
- Icons: 24x24px

### Sections
1. Header with logo
2. Greeting
3. Order summary card
4. Pricing breakdown
5. Order details
6. Action buttons
7. Footer with contact

## 🔧 Implementation Steps

### Step 1: Email Template
1. Create professional HTML email template
2. Add product image support
3. Include pricing breakdown
4. Test email delivery
5. Verify spam score

### Step 2: Database Migration
1. Add new columns to orders table
2. Create quotation-order link
3. Migrate existing data
4. Add indexes

### Step 3: Backend Routes
1. Create order-from-quotation endpoint
2. Update email sending function
3. Add price calculation logic
4. Implement discount handling

### Step 4: Frontend Updates
1. Remove button from products page
2. Add button to quotation page
3. Update modal for quotation context
4. Add price editing UI

### Step 5: Testing
1. Test email delivery
2. Verify data pre-fill
3. Test price calculations
4. Check discount logic
5. Verify order creation

### Step 6: Deployment
1. Run database migration
2. Deploy backend changes
3. Deploy frontend updates
4. Configure SMTP settings
5. Monitor email delivery

## 📝 Notes

- Keep existing order setup functionality as fallback
- Maintain backward compatibility
- Add feature flags for gradual rollout
- Document all changes
- Create user guide for admins

## 🚀 Benefits

1. **Better Workflow**: Natural progression from quotation to order
2. **Less Data Entry**: Auto-fill from quotation
3. **Professional Emails**: Branded, detailed order confirmations
4. **Price Flexibility**: Easy discount application
5. **Better Tracking**: Link orders to quotations
6. **Improved UX**: Contextual order creation

## 📅 Timeline

- Email Template: 2 hours
- Database Updates: 1 hour
- Backend Routes: 3 hours
- Frontend Updates: 2 hours
- Testing: 2 hours
- **Total: ~10 hours**

---

**Status:** Planning Complete
**Next Step:** Implement professional email template
**Priority:** High