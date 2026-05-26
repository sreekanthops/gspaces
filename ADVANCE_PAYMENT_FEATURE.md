# Advance Payment & Delivery Date Feature

## Overview
This feature adds support for tracking advance payments and expected delivery dates in the quotation-to-order workflow. It also updates the email template to reflect that orders are created after discussion (not before).

## Changes Made

### 1. Database Schema Changes
**File:** `add_advance_payment_delivery_date.sql`

Added three new columns to the `orders` table:
- `advance_amount` (DECIMAL) - Amount paid in advance by customer
- `pending_amount` (DECIMAL) - Remaining amount to be paid (auto-calculated)
- `expected_delivery_date` (DATE) - Expected delivery date for the order

### 2. Email Template Updates
**File:** `templates/email_professional_order.html`

#### Changes to "What's Next?" Section (Lines 197-210)
**Before:**
```html
<h3>📞 What's Next?</h3>
<ul>
  <li>Our team will call you at <phone> within 24 hours</li>
  <li>We'll confirm all details and discuss customization options</li>
  <li>Delivery timeline and installation will be scheduled</li>
  <li>You'll receive updates via email as your order progresses</li>
</ul>
```

**After:**
```html
<h3>📋 Order Details Confirmed</h3>
<ul>
  <li>All details have been discussed and confirmed with our team</li>
  <li>Your order is now being processed</li>
  <li>Expected delivery date: [DATE] (if provided)</li>
  <li>You'll receive updates via email as your order progresses</li>
</ul>
```

#### New Payment Summary Section
Added a new section that displays when advance amount > 0:
```html
<h3>💳 Payment Summary</h3>
<table>
  <tr><td>Total Amount:</td><td>₹X,XXX</td></tr>
  <tr><td>Advance Paid:</td><td>₹X,XXX</td></tr>
  <tr><td>Pending Amount:</td><td>₹X,XXX</td></tr>
</table>
```

#### Updated Footer Contact Details (Lines 224-236)
**Before:**
```
📧 {{ company_email }} | 📞 {{ company_phone }}
```

**After:**
```
📧 sreekanth.chityala@gspaces.in | 📞 +91-7075077384
🌐 gspaces.in
```

### 3. Quotation Form Updates
**File:** `templates/quotation_view_simple.html`

#### New Fields Added (After line 2512):

**Advance Amount Field:**
```html
<div class="mb-3">
  <label>Advance Amount Received</label>
  <input type="number" name="advance_amount" min="0" step="0.01" value="0">
  <small>Amount already paid by customer</small>
</div>
```

**Pending Amount Display (Auto-calculated):**
```html
<div class="alert alert-warning">
  <strong>⏳ Pending Amount:</strong> ₹<span id="pendingAmount">0</span>
</div>
```

**Expected Delivery Date (Calendar Picker):**
```html
<div class="mb-3">
  <label>Expected Delivery Date</label>
  <input type="date" name="expected_delivery_date" class="form-control">
  <small>When will the order be delivered?</small>
</div>
```

#### New JavaScript Function:
```javascript
function calculatePendingAmount() {
    const finalPrice = parseFloat(document.getElementById('finalPrice').value) || 0;
    const advanceAmount = parseFloat(document.getElementById('advanceAmount').value) || 0;
    const pendingAmount = Math.max(0, finalPrice - advanceAmount);
    document.getElementById('pendingAmount').textContent = pendingAmount.toFixed(0);
}
```

### 4. Backend Route Updates
**File:** `quotation_order_routes.py`

#### New Parameters Handled (Line 254):
```python
advance_amount = float(data.get('advance_amount', 0))
expected_delivery_date = data.get('expected_delivery_date', '').strip() or None
```

#### Pending Amount Calculation (Line 324):
```python
pending_amount = final_price - Decimal(str(advance_amount))
```

#### Database Insert/Update (Lines 341-445):
- Added `advance_amount`, `pending_amount`, `expected_delivery_date` to INSERT statement
- Added same fields to UPDATE statement for existing orders

#### Email Data (Lines 563-595):
```python
order_data = {
    # ... existing fields ...
    'advance_amount': float(advance_amount),
    'pending_amount': float(pending_amount),
    'expected_delivery_date': formatted_delivery_date,
    # ... other fields ...
}
```

## Deployment Instructions

### Step 1: Run Database Migration
```bash
psql -U postgres -d gspaces -f add_advance_payment_delivery_date.sql
```

### Step 2: Verify Database Changes
```bash
psql -U postgres -d gspaces -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'orders' AND column_name IN ('advance_amount', 'pending_amount', 'expected_delivery_date');"
```

### Step 3: Restart Application
```bash
# Using systemd
sudo systemctl restart gspaces

# Or manually
pkill -f "python.*main.py" && nohup python main.py &
```

### Quick Deploy (All Steps)
```bash
chmod +x deploy_advance_payment_feature.sh
./deploy_advance_payment_feature.sh
```

## Usage

### For Admins (Creating Orders from Quotations)

1. Open a quotation page
2. Click "Create Order" button
3. Fill in the form:
   - **Customer Type**: Select customer type
   - **Discount Percentage**: Enter discount (optional)
   - **Final Price**: Adjust if needed
   - **Advance Amount**: Enter amount already paid by customer
   - **Pending Amount**: Auto-calculated (Final Price - Advance)
   - **Expected Delivery Date**: Select date from calendar picker
   - **Delivery Address**: Enter or confirm address
   - **Admin Notes**: Internal notes (optional)
4. Click "Create Order & Send Email"

### Email Behavior

**When advance amount = 0:**
- Payment Summary section is hidden
- Only "Order Details Confirmed" section is shown

**When advance amount > 0:**
- Payment Summary section is displayed showing:
  - Total Amount
  - Advance Paid (in green)
  - Pending Amount (in red)
- "Order Details Confirmed" section follows

**Delivery Date:**
- If provided, shows in "Order Details Confirmed" section
- Format: "Expected delivery date: January 15, 2026"

## Testing Checklist

- [ ] Database migration runs successfully
- [ ] New columns appear in orders table
- [ ] Quotation form shows new fields
- [ ] Advance amount field accepts decimal values
- [ ] Pending amount auto-calculates correctly
- [ ] Date picker works and accepts future dates
- [ ] Order creation saves all new fields
- [ ] Email includes payment summary when advance > 0
- [ ] Email shows delivery date when provided
- [ ] Email footer shows updated contact details
- [ ] "Order Details Confirmed" section replaces "What's Next?"

## Rollback Instructions

If you need to rollback these changes:

```sql
-- Remove new columns
ALTER TABLE orders 
DROP COLUMN IF EXISTS advance_amount,
DROP COLUMN IF EXISTS pending_amount,
DROP COLUMN IF EXISTS expected_delivery_date;
```

Then restore the previous versions of:
- `templates/email_professional_order.html`
- `templates/quotation_view_simple.html`
- `quotation_order_routes.py`

## Support

For issues or questions, contact:
- Email: sreekanth.chityala@gspaces.in
- Phone: +91-7075077384
- Website: gspaces.in

---

**Made with Bob** 🤖