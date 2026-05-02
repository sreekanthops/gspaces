# Quantity-Based Items Implementation Guide

## Overview
Complete redesign of the items system to support:
- Quantity fields for ALL items (17 total)
- Unit price × quantity = total price
- 11 new permanent item types
- Icons for each item
- Customer view shows quantities and custom items

## Item List (17 Total)

### Original Items (6):
1. **Desk** 🪑 - table_*
2. **Chair** 💺 - chair_*
3. **Plants & Decor** 🪴 - plants_* (keeping for backward compatibility)
4. **Lighting** 💡 - lighting_*
5. **Storage** 📦 - storage_*
6. **Accessories** ✨ - accessories_*

### New Items (11):
7. **Big Plants** 🌳 - big_plants_*
8. **Mini Plants** 🌱 - mini_plants_*
9. **Frames** 🖼️ - frames_*
10. **Wall Racks** 📚 - wall_racks_*
11. **Desk Mat** 🎯 - deskmat_*
12. **Dustbin** 🗑️ - dustbin_*
13. **Floor Mat** 🟫 - floor_mat_*
14. **Keyboard** ⌨️ - keyboard_*
15. **Mouse** 🖱️ - mouse_*
16. **Paint** 🎨 - paint_*
17. **Wardrobes** 🚪 - wardrobes_*

## Database Schema

Each item has 4 fields:
- `has_{item}` - BOOLEAN (checkbox)
- `{item}_quantity` - INTEGER (default 1)
- `{item}_price` - DECIMAL (unit price)
- `{item}_details` - TEXT (description)

**Calculation**: `total_for_item = quantity × price`

## Implementation Steps

### Phase 1: Database ✅
- [x] Create migration with all fields
- File: `add_item_quantities.sql`

### Phase 2: Backend (leads_simple.py)
Update `update_design()` function to:
1. Get all 17 items' has/quantity/price/details
2. Calculate subtotal: sum of (quantity × price) for all items
3. Apply discount
4. Update database with all fields

### Phase 3: Admin Form (edit_lead_simple.html)
For each item, add:
```html
<div class="item-checkbox">
    <label>
        <input type="checkbox" name="has_{item}">
        <strong>Icon Item Name</strong>
    </label>
    <div class="item-details">
        <div class="row">
            <div class="col-md-4">
                <input type="number" name="{item}_quantity" 
                       placeholder="Qty" min="1" value="1"
                       onchange="calculateItemTotal('{item}'); calculateTotal(designId)">
            </div>
            <div class="col-md-4">
                <input type="number" name="{item}_price" 
                       placeholder="Unit Price (₹)" step="0.01"
                       onchange="calculateItemTotal('{item}'); calculateTotal(designId)">
            </div>
            <div class="col-md-4">
                <input type="number" id="{item}_total" 
                       placeholder="Total" readonly>
            </div>
        </div>
        <textarea name="{item}_details" placeholder="Details"></textarea>
    </div>
</div>
```

### Phase 4: Customer View (quotation_view_simple.html)
Show each item with quantity:
```html
{% if design.has_{item} %}
<div class="item-row">
    <div class="item-icon">Icon</div>
    <div class="item-content">
        <div class="item-title">
            Item Name 
            {% if design.{item}_quantity > 1 %}
                <span class="badge bg-secondary">× {{ design.{item}_quantity }}</span>
            {% endif %}
        </div>
        {% if design.{item}_details %}
        <div class="item-details">{{ design.{item}_details }}</div>
        {% endif %}
    </div>
</div>
{% endif %}
```

### Phase 5: Custom Items Display
Show custom items in customer view:
```html
{% if design.custom_items %}
    {% for item in design.custom_items %}
    <div class="item-row">
        <div class="item-icon">{{ item.icon }}</div>
        <div class="item-content">
            <div class="item-title">
                {{ item.name }}
                {% if item.quantity and item.quantity > 1 %}
                    <span class="badge bg-secondary">× {{ item.quantity }}</span>
                {% endif %}
            </div>
            {% if item.details %}
            <div class="item-details">{{ item.details }}</div>
            {% endif %}
        </div>
    </div>
    {% endfor %}
{% endif %}
```

### Phase 6: JavaScript Calculations
```javascript
function calculateItemTotal(itemName) {
    const qty = parseFloat(document.querySelector(`[name="${itemName}_quantity"]`).value || 1);
    const price = parseFloat(document.querySelector(`[name="${itemName}_price"]`).value || 0);
    const total = qty * price;
    document.getElementById(`${itemName}_total`).value = total.toFixed(2);
}

function calculateTotal(designId) {
    let subtotal = 0;
    
    // List of all 17 items
    const items = [
        'table', 'chair', 'plants', 'lighting', 'storage', 'accessories',
        'big_plants', 'mini_plants', 'frames', 'wall_racks', 'deskmat',
        'dustbin', 'floor_mat', 'keyboard', 'mouse', 'paint', 'wardrobes'
    ];
    
    items.forEach(item => {
        const qty = parseFloat(document.querySelector(`[name="${item}_quantity"]`)?.value || 1);
        const price = parseFloat(document.querySelector(`[name="${item}_price"]`)?.value || 0);
        subtotal += qty * price;
    });
    
    // Add custom items
    const customPrices = document.querySelectorAll('[name="custom_item_price[]"]');
    const customQtys = document.querySelectorAll('[name="custom_item_quantity[]"]');
    customPrices.forEach((priceInput, idx) => {
        const price = parseFloat(priceInput.value || 0);
        const qty = parseFloat(customQtys[idx]?.value || 1);
        subtotal += price * qty;
    });
    
    // Update subtotal and apply discount...
}
```

## Customer View Examples

### Example 1: Single Quantity
```
✓ Desk - Ergonomic standing desk
✓ Chair - Premium office chair
```

### Example 2: Multiple Quantities
```
✓ Desk ×2 - Ergonomic standing desk
✓ Chair ×4 - Premium office chair
✓ Frames ×3 - Wall art frames
```

### Example 3: With Custom Items
```
✓ Desk - Ergonomic standing desk
✓ Chair ×2 - Premium office chair
✓ Monitor Stand ×2 - Adjustable height
✓ Cable Organizer - Under desk
```

## Deployment

```bash
# 1. Apply migration
psql -U sri -d gspaces -f add_item_quantities.sql

# 2. Update code files
# (leads_simple.py, edit_lead_simple.html, quotation_view_simple.html)

# 3. Restart
sudo systemctl restart python3
```

## Benefits

1. **Accurate Pricing**: Quantity × unit price
2. **Flexibility**: 17 item types to choose from
3. **Professional**: Shows quantities in customer view
4. **Transparent**: Custom items visible to customers
5. **Scalable**: Easy to add more items in future

---
**Status**: Ready for Implementation
**Estimated Time**: 2-3 hours for complete implementation
**Complexity**: High (many fields, calculations, UI changes)