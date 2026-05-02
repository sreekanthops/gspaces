# Individual Item Pricing & Discount System

## Overview
Complete pricing system with individual item prices, automatic total calculation, and flexible discount options (percentage or fixed amount).

## Features Implemented

### 1. Individual Item Pricing
- **Each standard item has its own price field**:
  - Desk/Table
  - Chair
  - Plants & Decor
  - Lighting
  - Storage Solutions
  - Accessories
- **Custom items also have price fields**
- **Automatic subtotal calculation** from all items

### 2. Discount System
Admin can choose:
- **No Discount**: Regular pricing
- **Percentage Discount**: e.g., 10% off, 25% off
- **Fixed Amount Discount**: e.g., ₹5,000 off, ₹10,000 off

### 3. Customer View
- **With Discount**: Shows original price crossed out + discount badge + final price in green
- **Without Discount**: Shows regular price
- **Discount Badge**: Shows either "X% OFF" or "₹X OFF"

## Database Schema

### New Columns in `lead_designs` table:
```sql
-- Individual item prices
table_price DECIMAL(10,2) DEFAULT 0
chair_price DECIMAL(10,2) DEFAULT 0
plants_price DECIMAL(10,2) DEFAULT 0
lighting_price DECIMAL(10,2) DEFAULT 0
storage_price DECIMAL(10,2) DEFAULT 0
accessories_price DECIMAL(10,2) DEFAULT 0

-- Discount fields
discount_type VARCHAR(20) DEFAULT 'none'  -- 'none', 'percentage', 'fixed'
discount_value DECIMAL(10,2) DEFAULT 0

-- Calculated totals
subtotal DECIMAL(10,2) DEFAULT 0
final_price DECIMAL(10,2) DEFAULT 0
```

### Custom Items JSON Structure:
```json
[
  {
    "name": "Monitor Stand",
    "details": "Adjustable height",
    "icon": "🖥️",
    "price": 2500
  }
]
```

## Admin Interface

### Edit Design Form:
1. **Item Checkboxes** - Enable/disable items
2. **Item Details** - Description textarea
3. **Item Price** - Price input field (₹)
4. **Custom Items** - Add unlimited items with prices
5. **Pricing Summary Section**:
   - **Subtotal** (read-only, auto-calculated)
   - **Discount Type** dropdown (None/Percentage/Fixed)
   - **Discount Value** input (disabled when "None")
   - **Final Price** (read-only, auto-calculated)

### JavaScript Auto-Calculation:
- Triggers on any price change
- Sums all item prices
- Applies discount
- Updates subtotal and final price fields
- Runs on page load for existing designs

## Customer Quotation View

### Without Discount:
```
₹45,000
```

### With Percentage Discount (20% off):
```
₹50,000  [20% OFF]
₹40,000
```

### With Fixed Discount (₹5,000 off):
```
₹45,000  [₹5,000 OFF]
₹40,000
```

## Usage Examples

### Example 1: Basic Setup
1. Admin creates design
2. Checks "Desk" and enters ₹15,000
3. Checks "Chair" and enters ₹8,000
4. Checks "Lighting" and enters ₹3,000
5. **Subtotal**: ₹26,000 (auto-calculated)
6. No discount
7. **Final Price**: ₹26,000

### Example 2: With Percentage Discount
1. Same items, subtotal ₹26,000
2. Select "Percentage" discount
3. Enter 15
4. **Final Price**: ₹22,100 (auto-calculated)
5. Customer sees: ~~₹26,000~~ **[15% OFF]** ₹22,100

### Example 3: With Fixed Discount
1. Same items, subtotal ₹26,000
2. Select "Fixed Amount" discount
3. Enter 5000
4. **Final Price**: ₹21,000 (auto-calculated)
5. Customer sees: ~~₹26,000~~ **[₹5,000 OFF]** ₹21,000

### Example 4: With Custom Items
1. Standard items: ₹26,000
2. Add custom item "Monitor" - ₹12,000
3. Add custom item "Keyboard" - ₹3,000
4. **Subtotal**: ₹41,000 (auto-calculated)
5. Apply 10% discount
6. **Final Price**: ₹36,900
7. Customer sees: ~~₹41,000~~ **[10% OFF]** ₹36,900

## Deployment Steps

### 1. Apply Database Migration
```bash
cd ~/gspaces
psql -U sri -d gspaces -f add_item_pricing_and_discounts.sql
```

### 2. Verify Migration
```bash
psql -U sri -d gspaces -c "\d lead_designs"
```

Should show new columns:
- table_price, chair_price, plants_price, lighting_price, storage_price, accessories_price
- discount_type, discount_value
- subtotal, final_price

### 3. Update Application Files
Files already updated:
- `leads_simple.py` - Backend logic
- `templates/edit_lead_simple.html` - Admin interface
- `templates/quotation_view_simple.html` - Customer view

### 4. Restart Application
```bash
sudo systemctl restart python3
```

### 5. Test the Feature
1. Go to Admin → Leads
2. Edit existing lead or create new one
3. Add design with items and prices
4. Verify subtotal auto-calculates
5. Apply discount and verify final price
6. View quotation and verify display
7. Test with different discount types

## Technical Details

### JavaScript Functions

**calculateTotal(designId)**
- Sums all item prices (standard + custom)
- Calculates discount based on type
- Updates subtotal and final price fields
- Ensures final price is never negative

**toggleDiscountInput(select, designId)**
- Enables/disables discount value input
- Resets value to 0 when "None" selected
- Triggers recalculation

**addCustomItem(designId)**
- Adds new custom item row with price field
- Includes onchange handler for auto-calculation

### Backend Calculation (leads_simple.py)

```python
# Calculate subtotal
subtotal = (table_price + chair_price + plants_price + 
            lighting_price + storage_price + accessories_price)
subtotal += sum(item['price'] for item in custom_items)

# Apply discount
final_price = subtotal
if discount_type == 'percentage':
    final_price = subtotal - (subtotal * discount_value / 100)
elif discount_type == 'fixed':
    final_price = subtotal - discount_value
final_price = max(0, final_price)  # Non-negative
```

## Benefits

1. **Transparency**: Customers see exactly what they're paying for
2. **Flexibility**: Admin can price each item individually
3. **Professional**: Automatic calculations prevent errors
4. **Marketing**: Discount display encourages purchases
5. **Scalability**: Unlimited custom items with prices
6. **User-Friendly**: Real-time calculation, no manual math

## Best Practices

### For Admins:
1. **Price Consistently**: Use similar pricing for similar items across designs
2. **Round Numbers**: Use ₹5,000 instead of ₹4,999 for professional look
3. **Strategic Discounts**: Use percentage for higher-value items, fixed for lower
4. **Clear Descriptions**: Help justify the price with good item details
5. **Test Calculations**: Always preview quotation before sharing

### For Discounts:
1. **Percentage**: Better for high-value packages (10-25% typical)
2. **Fixed Amount**: Better for specific promotions (₹5,000 off, ₹10,000 off)
3. **Seasonal**: Adjust discounts based on demand
4. **Competitive**: Research market rates before setting prices

## Troubleshooting

### Issue: Subtotal not calculating
- **Solution**: Check browser console for JavaScript errors
- **Solution**: Ensure all price inputs have valid numbers

### Issue: Discount not applying
- **Solution**: Verify discount_type is not 'none'
- **Solution**: Check discount_value is greater than 0

### Issue: Negative final price
- **Solution**: Backend prevents this with `max(0, final_price)`
- **Solution**: Reduce discount value

### Issue: Custom item prices not included
- **Solution**: Ensure custom_item_price[] fields have values
- **Solution**: Check JSON parsing in backend

## Future Enhancements

1. **Tax Calculation**: Add GST/tax fields
2. **Payment Terms**: Add installment options
3. **Bulk Discounts**: Automatic discounts for multiple designs
4. **Price History**: Track price changes over time
5. **Competitor Comparison**: Show market price vs. our price
6. **Dynamic Pricing**: AI-based pricing suggestions

---
**Feature Status**: ✅ Complete and Ready for Deployment
**Last Updated**: May 2, 2026
**Version**: 2.0