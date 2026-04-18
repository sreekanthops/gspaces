#!/bin/bash

# Quick Implementation Script for Remaining Features
# This script contains all the SQL and instructions needed

echo "=========================================="
echo "Implementing Remaining Bonus Coupon Features"
echo "=========================================="
echo ""

echo "📋 What this will do:"
echo "1. Show bonus coupons in user wallet/profile page"
echo "2. Add bonus coupons column in admin referral page"
echo "3. Send email for all user changes (referral updates)"
echo ""

echo "⚠️  IMPORTANT: You need to manually update these files:"
echo ""
echo "=== FILE 1: main.py (profile route) ==="
echo "Find the profile route (around line 1900-2000) and add this after wallet_transactions query:"
echo ""
cat << 'EOF'
# Fetch user's bonus coupons
try:
    cur.execute("""
        SELECT code, discount_type, discount_value, description, 
               valid_until, is_active, created_at
        FROM coupons
        WHERE user_id = %s AND is_personal = TRUE
        ORDER BY created_at DESC
    """, (current_user.id,))
    bonus_coupons = cur.fetchall()
except Exception as e:
    print(f"Error fetching bonus coupons: {e}")
    bonus_coupons = []
EOF

echo ""
echo "Then add bonus_coupons to the render_template call:"
echo "return render_template('profile.html', ..., bonus_coupons=bonus_coupons)"
echo ""
echo "=========================================="
echo ""

echo "=== FILE 2: templates/profile.html ==="
echo "Add this after the Wallet Benefits card (around line 470):"
echo ""
cat << 'EOF'
<!-- My Bonus Coupons -->
<div class="col-md-6">
    <div class="info-card" style="border: 2px solid #8b5cf6;">
        <h5 class="mb-3"><i class="bi bi-gift-fill me-2" style="color: #8b5cf6;"></i>My Bonus Coupons</h5>
        {% if bonus_coupons and bonus_coupons|length > 0 %}
            {% for coupon in bonus_coupons %}
            <div style="border: 2px dashed #8b5cf6; padding: 12px; margin-bottom: 12px; border-radius: 8px; background: linear-gradient(135deg, rgba(139, 92, 246, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <div>
                        <strong style="font-family: monospace; font-size: 18px; color: #8b5cf6;">{{ coupon.code }}</strong>
                        <br>
                        <span class="badge" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                            {% if coupon.discount_type == 'fixed' %}
                                ₹{{ coupon.discount_value|int }} OFF
                            {% else %}
                                {{ coupon.discount_value }}% OFF
                            {% endif %}
                        </span>
                    </div>
                    <button class="btn btn-sm btn-outline-primary" onclick="navigator.clipboard.writeText('{{ coupon.code }}'); alert('Coupon code copied!');" title="Copy code">
                        <i class="bi bi-clipboard"></i>
                    </button>
                </div>
                {% if coupon.description %}
                <small class="text-muted d-block">{{ coupon.description }}</small>
                {% endif %}
                <small class="text-muted d-block mt-1">
                    <i class="bi bi-calendar-event"></i> Expires: {{ coupon.valid_until.strftime('%b %d, %Y') if coupon.valid_until else 'No expiry' }}
                </small>
            </div>
            {% endfor %}
        {% else %}
            <div class="text-center py-3">
                <i class="bi bi-gift" style="font-size: 2rem; color: #d1d5db;"></i>
                <p class="text-muted mb-0 mt-2">No bonus coupons yet. Check back later!</p>
            </div>
        {% endif %}
    </div>
</div>
EOF

echo ""
echo "=========================================="
echo ""

echo "=== FILE 3: admin_referral_routes.py ==="
echo "Update the admin_referral_coupons route query (around line 40-50):"
echo ""
cat << 'EOF'
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
EOF

echo ""
echo "=========================================="
echo ""

echo "=== FILE 4: templates/admin_referral_coupons.html ==="
echo "Add column header (around line 315):"
echo "<th>Bonus Coupons</th>"
echo ""
echo "Add column data (around line 337, after wallet balance):"
echo ""
cat << 'EOF'
<td>
    {% if coupon.bonus_coupons %}
        <div style="max-height: 80px; overflow-y: auto;">
            {% for bc in coupon.bonus_coupons.split(',') %}
            <span class="badge mb-1" style="display: block; font-size: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                {{ bc }}
            </span>
            {% endfor %}
        </div>
    {% else %}
        <span class="text-muted" style="font-size: 12px;">None</span>
    {% endif %}
</td>
EOF

echo ""
echo "=========================================="
echo ""

echo "=== FILE 5: admin_referral_routes.py (Email for all changes) ==="
echo "Update the success message section (around line 312-320) to:"
echo ""
cat << 'EOF'
# Build comprehensive email about all changes
changes_made = []
if wallet_updated:
    changes_made.append(f"💰 Wallet: Adjusted by ₹{wallet_adjustment} (New balance: ₹{new_balance:.2f})")
if personal_coupon_created:
    changes_made.append(f"🎁 Bonus Coupon: {personal_coupon_code} created")

# Check if referral settings were updated
referral_updated = any([
    request.form.get('discount_amount'),
    request.form.get('referrer_bonus_amount')
])
if referral_updated:
    changes_made.append(f"🎯 Referral Rewards: Updated")

# Send email if any changes were made
if changes_made:
    try:
        from email_helper import send_referral_update_email
        send_referral_update_email(
            user_email=user_email,
            user_name=user_name,
            referral_code=referral_code,
            wallet_adjustment=wallet_updated,
            new_wallet_balance=new_balance if wallet_updated else None,
            wallet_adjustment_reason=wallet_reason if wallet_updated else None,
            referral_benefits_updated=referral_updated,
            personal_coupon_code=personal_coupon_code if personal_coupon_created else None
        )
    except Exception as email_error:
        print(f"Failed to send update email: {email_error}")
EOF

echo ""
echo "=========================================="
echo ""

echo "✅ All code snippets provided above!"
echo ""
echo "📝 Manual Steps Required:"
echo "1. Update main.py - Add bonus_coupons query to profile route"
echo "2. Update templates/profile.html - Add bonus coupons display"
echo "3. Update admin_referral_routes.py - Add STRING_AGG for bonus coupons"
echo "4. Update templates/admin_referral_coupons.html - Add bonus coupons column"
echo "5. Update admin_referral_routes.py - Send email for all changes"
echo ""
echo "🔧 SMTP Email Fix (separate issue):"
echo "The email error is due to Gmail SMTP credentials."
echo "You need to set these environment variables on your server:"
echo "  export SMTP_USERNAME='your-email@gmail.com'"
echo "  export SMTP_PASSWORD='your-app-password'"
echo ""
echo "To get Gmail app password:"
echo "1. Go to Google Account settings"
echo "2. Security > 2-Step Verification"
echo "3. App passwords > Generate"
echo "4. Use that password in SMTP_PASSWORD"
echo ""
echo "=========================================="

# Made with Bob
