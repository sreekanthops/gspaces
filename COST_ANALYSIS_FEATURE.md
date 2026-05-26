# Cost Analysis & Profit Calculator Feature

## Overview
Added an admin-only cost analysis section in the quotation page to help calculate profit/loss and margins for each order.

## Features

### 1. **Automatic Item Fetching**
- Automatically displays all selected items from the current quotation
- Shows quantity, customer price, and total revenue for each item

### 2. **Manual Cost Entry**
- Admin can enter the actual cost price for each item
- Real-time calculation of profit/loss per item

### 3. **Additional Costs**
- Add transportation, installation, labor, and other costs
- Multiple additional cost items can be added
- Each has a name and amount field

### 4. **Profit Analysis**
- **Total Cost**: Sum of all item costs + additional costs
- **Customer Pays**: Final price after discount
- **Net Profit/Loss**: Customer Pays - Total Cost
- **Profit Margin %**: (Profit / Revenue) × 100

### 5. **Visual Indicators**
- **Profit/Loss**: Green for profit, Red for loss
- **Margin Colors**:
  - Green: ≥30% (Good margin)
  - Yellow: 15-30% (Moderate margin)
  - Red: <15% (Low margin)

## Location
The Cost Analysis section appears in the quotation edit page (`/admin/leads/edit/<lead_id>`) after the Pricing Summary section.

## Security
- **Admin Only**: This section is only visible to admin users
- **Not in Customer View**: Customers never see cost prices or profit calculations
- Clearly marked with "Admin Only - Internal" badge

## How to Use

1. **Create/Edit Quotation**
   - Add items and set customer prices as usual
   - Apply discounts if needed

2. **Enter Cost Prices**
   - Scroll to "Cost Analysis & Profit Calculator" section
   - Enter your actual cost price for each item
   - System automatically calculates item profit

3. **Add Additional Costs**
   - Click "Add Cost Item" button
   - Enter cost name (e.g., "Transportation", "Installation")
   - Enter amount
   - Add multiple costs as needed

4. **View Profit Analysis**
   - See total cost vs customer payment
   - Check profit/loss amount
   - Review profit margin percentage

## Files Modified
- `templates/edit_lead_simple.html` - Added HTML section and JavaScript functions

## Deployment
```bash
# Changes are already committed and pushed to 'order' branch
git checkout order
git pull origin order

# No database changes needed
# No server restart needed (template changes only)
```

## Example Calculation

**Items:**
- Table: Qty 1, Cost ₹5,000, Customer Price ₹8,000 → Profit ₹3,000
- Chair: Qty 2, Cost ₹2,000, Customer Price ₹3,500 → Profit ₹3,000

**Additional Costs:**
- Transportation: ₹1,000
- Installation: ₹500

**Final Analysis:**
- Total Cost: ₹11,500 (₹9,000 items + ₹1,500 additional)
- Customer Pays: ₹11,500 (after discount)
- Net Profit: ₹0
- Margin: 0%

## Notes
- Cost prices are entered per quotation, not saved globally
- Each quotation can have different cost prices
- "Manage Default Prices" page remains unchanged
- This is for internal analysis only

## Support
For issues or questions, contact the development team.

---
**Made with Bob** 🤖