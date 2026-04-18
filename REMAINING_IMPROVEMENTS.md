# Remaining Improvements for Bonus Coupon Feature

## ✅ Completed So Far

1. ✅ Fixed wallet adjustment (balance_after column)
2. ✅ Removed old "Adjust Wallet" button
3. ✅ Created bonus coupon feature (BONUS_USERNAME_RANDOM)
4. ✅ Email notifications for bonus coupons
5. ✅ Display bonus coupons in cart with badge
6. ✅ Changed naming from PERSONAL to BONUS

## 🔄 Remaining Tasks

### 1. Show Bonus Coupons in User Profile/Wallet Page

**Location**: `templates/profile.html` - Wallet section

**What to Add**: A "My Bonus Coupons" card showing:
- List of user's bonus coupons
- Coupon code (large, copyable)
- Discount amount
- Expiry date
- Status (Active/Expired)

**Backend**: Update profile route in `main.py` to fetch user's bonus coupons:
```python
# In profile route
cur.execute("""
    SELECT code, discount_type, discount_value, description, 
           valid_until, is_active
    FROM coupons
    WHERE user_id = %s AND is_personal = TRUE
    ORDER BY created_at DESC
""", (current_user.id,))
bonus_coupons = cur.fetchall()
```

**Frontend**: Add after wallet balance card (around line 455):
```html
<!-- My Bonus Coupons -->
<div class="col-md-6">
    <div class="info-card">
        <h5 class="mb-3"><i class="bi bi-gift-fill text-purple me-2"></i>My Bonus Coupons</h5>
        {% if bonus_coupons and bonus_coupons|length > 0 %}
            {% for coupon in bonus_coupons %}
            <div class="coupon-item" style="border: 2px dashed #8b5cf6; padding: 12px; margin-bottom: 12px; border-radius: 8px;">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <strong style="font-family: monospace; font-size: 16px; color: #8b5cf6;">{{ coupon.code }}</strong>
                        <br>
                        <span class="badge bg-success">
                            {% if coupon.discount_type == 'fixed' %}
                                ₹{{ coupon.discount_value }} OFF
                            {% else %}
                                {{ coupon.discount_value }}% OFF
                            {% endif %}
                        </span>
                    </div>
                    <button class="btn btn-sm btn-outline-primary" onclick="copyCoupon('{{ coupon.code }}')">
                        <i class="bi bi-clipboard"></i> Copy
                    </button>
                </div>
                {% if coupon.description %}
                <small class="text-muted d-block mt-2">{{ coupon.description }}</small>
                {% endif %}
                <small class="text-muted d-block mt-1">
                    Expires: {{ coupon.valid_until.strftime('%b %d, %Y') if coupon.valid_until else 'No expiry' }}
                </small>
            </div>
            {% endfor %}
        {% else %}
            <p class="text-muted mb-0">No bonus coupons yet. Check back later!</p>
        {% endif %}
    </div>
</div>
```

**JavaScript**: Add copy function:
```javascript
function copyCoupon(code) {
    navigator.clipboard.writeText(code);
    alert('Coupon code copied: ' + code);
}
```

---

### 2. Add "Bonus Coupons" Column in Admin Referral Page

**Location**: `templates/admin_referral_coupons.html`

**What to Add**: New column showing bonus coupons for each user

**Table Header** (around line 315):
```html
<th>Bonus Coupons</th>
```

**Table Body** (around line 337):
```html
<td>
    {% if coupon.bonus_coupons %}
        <div style="max-height: 100px; overflow-y: auto;">
            {% for bc in coupon.bonus_coupons.split(',') %}
            <span class="badge bg-purple mb-1" style="display: block; font-size: 10px;">
                {{ bc }}
            </span>
            {% endfor %}
        </div>
    {% else %}
        <span class="text-muted">None</span>
    {% endif %}
</td>
```

**Backend**: Update admin route in `admin_referral_routes.py`:
```python
# In admin_referral_coupons route
cur.execute("""
    SELECT
        rc.*,
        u.name as user_name,
        u.email as user_email,
        COALESCE(w.balance, 0) as wallet_balance,
        STRING_AGG(c.code, ',' ORDER BY c.created_at DESC) as bonus_coupons
    FROM referral_coupons rc
    JOIN users u ON rc.user_id = u.id
    LEFT JOIN wallets w ON u.id = w.user_id
    LEFT JOIN coupons c ON u.id = c.user_id AND c.is_personal = TRUE AND c.is_active = TRUE
    GROUP BY rc.id, u.name, u.email, w.balance
    ORDER BY rc.created_at DESC
""")
```

---

### 3. Send Email for ALL User-Related Changes

**What to Update**: Modify the update route to ALWAYS send email when changes are made

**Location**: `admin_referral_routes.py` - `/admin/referral-coupons/update` route

**Current Issue**: Email only sent for wallet adjustment and bonus coupon creation

**Solution**: Send comprehensive email for ANY changes:

```python
# After all updates are committed
try:
    # Prepare email content based on what changed
    changes = []
    
    if wallet_updated:
        changes.append(f"Wallet balance adjusted by ₹{wallet_adjustment}")
    
    if personal_coupon_created:
        changes.append(f"New bonus coupon created: {personal_coupon_code}")
    
    # Check if referral settings changed
    if any([discount_type, discount_amount, referrer_bonus_amount]):
        changes.append("Referral rewards updated")
    
    # Send unified email
    if changes:
        send_user_update_email(
            user_email=user_email,
            user_name=user_name,
            changes=changes,
            referral_code=referral_code,
            wallet_balance=new_balance if wallet_updated else None,
            bonus_coupon=personal_coupon_code if personal_coupon_created else None
        )
except Exception as email_error:
    print(f"Failed to send update email: {email_error}")
```

**New Email Function** in `email_helper.py`:
```python
def send_user_update_email(user_email, user_name, changes, **kwargs):
    """
    Send email when any user-related changes are made by admin
    
    Args:
        user_email: User's email
        user_name: User's name
        changes: List of changes made
        **kwargs: Additional data (referral_code, wallet_balance, bonus_coupon, etc.)
    """
    # Create HTML email with all changes
    # Include sections for each type of change
    # Make it comprehensive and informative
```

---

## 📋 Implementation Checklist

- [ ] Update profile route to fetch bonus coupons
- [ ] Add bonus coupons display in profile.html
- [ ] Add copy coupon JavaScript function
- [ ] Update admin query to include bonus coupons
- [ ] Add bonus coupons column in admin table
- [ ] Create unified email function for all changes
- [ ] Update admin route to send email for all changes
- [ ] Test all features
- [ ] Deploy to server
- [ ] Verify emails are sent correctly

---

## 🧪 Testing Steps

1. **Profile Page**
   - Login as user
   - Go to profile/wallet
   - Should see "My Bonus Coupons" section
   - Click copy button - should copy code

2. **Admin Page**
   - Go to admin referral coupons
   - Should see "Bonus Coupons" column
   - Should show all bonus coupons for each user

3. **Email Notifications**
   - Make any change to user's referral settings
   - User should receive email
   - Make wallet adjustment - should receive email
   - Create bonus coupon - should receive email
   - All changes should be in ONE email if done together

---

## 📝 Notes

- Keep email notifications consolidated (one email for multiple changes)
- Make bonus coupons easily copyable in profile
- Show expiry dates clearly
- Admin should see all bonus coupons at a glance
- Consider adding filter/search for bonus coupons in admin

---

**Status**: Ready for implementation
**Priority**: High
**Estimated Time**: 2-3 hours