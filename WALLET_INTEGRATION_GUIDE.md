# Wallet System Integration Guide

This guide explains how to integrate the wallet and referral system into your gspaces application.

## Files Created

1. **add_wallet_system.sql** - Database migration script
2. **wallet_system.py** - Core wallet functionality module
3. **wallet_routes.py** - Flask routes for wallet operations
4. **wallet.html** - Wallet page template (to be created)

## Step 1: Run Database Migration

Execute the SQL migration to create all necessary tables:

```bash
cd /Users/sreekanthchityala/gspaces
psql -U sri -d gspaces -f add_wallet_system.sql
```

This will create:
- Wallet balance columns in users table
- wallet_transactions table
- referral_coupons table
- coupon_usage table
- Necessary indexes and triggers

## Step 2: Modify main.py

### 2.1 Add Imports (at the top of main.py, after existing imports)

```python
# Wallet system imports
from wallet_system import WalletSystem
from wallet_routes import add_wallet_routes, integrate_wallet_with_signup, integrate_wallet_with_order
```

### 2.2 Initialize Wallet Routes (after app initialization, around line 115)

```python
# Initialize wallet routes
add_wallet_routes(app, connect_to_db)
```

### 2.3 Modify Signup Route (around line 419-466)

Replace the signup function with this updated version:

```python
@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        try:
            name = request.form.get('name')
            email = request.form.get('email')
            password = request.form.get('password')
            referral_code = request.form.get('referral_code', '').strip().upper()  # NEW

            conn = connect_to_db()
            if not conn:
                flash("Database connection failed.", "error")
                return redirect(url_for('signup'))
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                flash("Email already registered. Please login.", "error")
                return render_template('login.html')

            # Validate referral code if provided
            referred_by_user_id = None
            if referral_code:
                cursor.execute("""
                    SELECT user_id FROM referral_coupons 
                    WHERE coupon_code = %s AND is_active = TRUE 
                    AND (expires_at IS NULL OR expires_at > NOW())
                """, (referral_code,))
                referrer = cursor.fetchone()
                if referrer:
                    referred_by_user_id = referrer['user_id']
                else:
                    flash("Invalid or expired referral code.", "warning")

            # Insert new user with referral info
            cursor.execute("""
                INSERT INTO users (name, email, password, referred_by_user_id)
                VALUES (%s, %s, %s, %s) RETURNING id, name, email
            """, (name, email, password, referred_by_user_id))
            new_user_data = cursor.fetchone()
            conn.commit()

            if new_user_data:
                user_id = new_user_data['id']
                
                # Credit signup bonus (₹500)
                integrate_wallet_with_signup(cursor, conn, user_id, name)
                
                # Automatically log in the new user
                new_user_obj = User(id=user_id, email=new_user_data['email'],
                                    name=new_user_data['name'], 
                                    is_admin=(new_user_data['email'] in ADMIN_EMAILS))
                login_user(new_user_obj)
                flash(f"Signup successful! ₹500 welcome bonus credited to your wallet.", "success")
                return redirect(url_for('index'))
            else:
                flash("Signup failed. Please try again.", "error")
                return render_template('login.html')

        except Exception as e:
            print(f"ERROR: Signup error: {e}")
            flash("Signup failed due to a server error. Please try again.", "error")
            return render_template('login.html')
        finally:
            if conn:
                cursor.close()
                conn.close()
    return render_template('login.html')
```

### 2.4 Modify Google OAuth Signup (around line 324-351)

Update the `upsert_user_from_google` function:

```python
def upsert_user_from_google(google_sub, name, email):
    """Insert user if missing; return (id, name, email)."""
    conn = connect_to_db()
    if not conn:
        return None
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, name, email FROM users WHERE email = %s", (email,))
        user_data = cur.fetchone()
        
        if not user_data:
            # New Google user - create account
            dummy_password = "oauth_user_no_password_" + ''.join(random.choices(string.ascii_letters + string.digits, k=16))
            cur.execute("""
                INSERT INTO users (name, email, password)
                VALUES (%s, %s, %s)
                RETURNING id, name, email
            """, (name or email.split("@")[0], email, dummy_password))
            user_data = cur.fetchone()
            conn.commit()
            
            # Credit signup bonus for new Google users
            if user_data:
                integrate_wallet_with_signup(cur, conn, user_data['id'], user_data['name'])
        
        return user_data
    except Exception as e:
        print(f"upsert_user_from_google error: {e}")
        return None
    finally:
        if conn:
            cur.close()
            conn.close()
```

### 2.5 Modify Payment Success Route (around line 2385-2520)

Update the payment_success function to integrate wallet:

Find this section (around line 2491):
```python
cur.execute("DELETE FROM cart WHERE user_id=%s", (current_user.id,))
conn.commit()
```

Add AFTER the commit and BEFORE the notification:

```python
        # Integrate wallet system
        wallet_amount_used = Decimal(str(data.get('wallet_amount_used', 0)))
        referral_code_used = data.get('referral_code_used')
        
        integrate_wallet_with_order(
            conn=conn,
            user_id=current_user.id,
            order_id=new_order_id,
            order_amount=final_total,
            wallet_amount_used=wallet_amount_used,
            referral_code_used=referral_code_used
        )
```

### 2.6 Update Cart Route to Include Wallet Info

Find the cart route (search for `@app.route('/cart')`) and add wallet balance info:

```python
@app.route('/cart')
@login_required
def cart():
    conn = connect_to_db()
    # ... existing code ...
    
    # Add wallet balance
    wallet = WalletSystem(conn)
    wallet_balance = wallet.get_wallet_balance(current_user.id)
    wallet_usage = wallet.calculate_wallet_usage(current_user.id, totals.get("total_with_gst", 0))
    
    # ... existing code ...
    
    return render_template('cart.html',
                         cart_items=cart_items,
                         totals=totals,
                         wallet_balance=float(wallet_balance),
                         wallet_usage=wallet_usage,  # NEW
                         # ... other existing parameters ...
                         )
```

## Step 3: Update Profile Route

Add wallet info to the profile page (search for `@app.route('/profile')`):

```python
@app.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    conn = connect_to_db()
    # ... existing code ...
    
    # Add wallet and referral info
    wallet = WalletSystem(conn)
    wallet_balance = wallet.get_wallet_balance(current_user.id)
    referral_stats = wallet.get_referral_stats(current_user.id)
    recent_transactions = wallet.get_transaction_history(current_user.id, 5)
    
    # ... existing code ...
    
    return render_template('profile.html',
                         user=user_data,
                         wallet_balance=float(wallet_balance),
                         referral_stats=referral_stats,
                         recent_transactions=recent_transactions,
                         # ... other existing parameters ...
                         )
```

## Step 4: Create Wallet Template

Create `templates/wallet.html`:

```html
{% extends "navbar.html" %}
{% block content %}
<div class="container mt-5">
    <h2>My Wallet</h2>
    
    <!-- Wallet Balance Card -->
    <div class="card mb-4">
        <div class="card-body">
            <h3>Current Balance: ₹{{ "%.2f"|format(balance) }}</h3>
            <p class="text-muted">Maximum bonus usage per order: ₹{{ "%.2f"|format(max_bonus_per_order) }}</p>
        </div>
    </div>
    
    <!-- Referral Section -->
    {% if referral_stats %}
    <div class="card mb-4">
        <div class="card-header">
            <h4>Your Referral Code</h4>
        </div>
        <div class="card-body">
            <div class="alert alert-info">
                <h5>{{ referral_stats.coupon_code }}</h5>
                <p>Share this code with friends! They get 5% off on their first order, and you get 5% bonus when they make a purchase.</p>
                <p><strong>Total Earnings:</strong> ₹{{ "%.2f"|format(referral_stats.total_earnings) }}</p>
                <p><strong>Times Used:</strong> {{ referral_stats.times_used }}</p>
                {% if referral_stats.expires_at %}
                <p><strong>Expires:</strong> {{ referral_stats.expires_at }}</p>
                {% endif %}
            </div>
            
            {% if referral_stats.referrals %}
            <h5>Referral History</h5>
            <table class="table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Date</th>
                        <th>Bonus Earned</th>
                    </tr>
                </thead>
                <tbody>
                    {% for ref in referral_stats.referrals %}
                    <tr>
                        <td>{{ ref.name }}</td>
                        <td>{{ ref.used_at }}</td>
                        <td>₹{{ "%.2f"|format(ref.bonus_earned) }}</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            {% endif %}
        </div>
    </div>
    {% endif %}
    
    <!-- Transaction History -->
    <div class="card">
        <div class="card-header">
            <h4>Transaction History</h4>
        </div>
        <div class="card-body">
            {% if transactions %}
            <table class="table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Description</th>
                        <th>Type</th>
                        <th>Amount</th>
                        <th>Balance</th>
                    </tr>
                </thead>
                <tbody>
                    {% for txn in transactions %}
                    <tr>
                        <td>{{ txn.date }}</td>
                        <td>{{ txn.description }}</td>
                        <td>
                            <span class="badge badge-{{ 'success' if txn.amount > 0 else 'danger' }}">
                                {{ txn.type }}
                            </span>
                        </td>
                        <td class="{{ 'text-success' if txn.amount > 0 else 'text-danger' }}">
                            {{ "+" if txn.amount > 0 else "" }}₹{{ "%.2f"|format(txn.amount) }}
                        </td>
                        <td>₹{{ "%.2f"|format(txn.balance_after) }}</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            {% else %}
            <p class="text-muted">No transactions yet.</p>
            {% endif %}
        </div>
    </div>
</div>
{% endblock %}
```

## Step 5: Update Cart Template

Add wallet payment option to `templates/cart.html`. Find the payment section and add:

```html
<!-- Wallet Payment Section -->
{% if wallet_balance > 0 %}
<div class="card mb-3">
    <div class="card-body">
        <h5>Use Wallet Balance</h5>
        <p>Available Balance: ₹{{ "%.2f"|format(wallet_balance) }}</p>
        <p>You can use up to ₹{{ "%.2f"|format(wallet_usage.max_usable) }} for this order</p>
        
        <div class="form-check">
            <input class="form-check-input" type="checkbox" id="useWallet" onchange="updateWalletUsage()">
            <label class="form-check-label" for="useWallet">
                Use wallet balance
            </label>
        </div>
        
        <div id="walletAmountSection" style="display:none;" class="mt-2">
            <label>Amount to use from wallet:</label>
            <input type="number" id="walletAmount" class="form-control" 
                   min="0" max="{{ wallet_usage.max_usable }}" 
                   step="0.01" value="{{ wallet_usage.max_usable }}"
                   onchange="updateOrderTotal()">
        </div>
    </div>
</div>
{% endif %}

<!-- Referral Code Section -->
<div class="card mb-3">
    <div class="card-body">
        <h5>Have a Referral Code?</h5>
        <div class="input-group">
            <input type="text" id="referralCode" class="form-control" placeholder="Enter referral code">
            <button class="btn btn-outline-secondary" onclick="validateReferralCode()">Apply</button>
        </div>
        <div id="referralMessage" class="mt-2"></div>
    </div>
</div>

<script>
function updateWalletUsage() {
    const useWallet = document.getElementById('useWallet').checked;
    document.getElementById('walletAmountSection').style.display = useWallet ? 'block' : 'none';
    updateOrderTotal();
}

function updateOrderTotal() {
    const useWallet = document.getElementById('useWallet').checked;
    const walletAmount = useWallet ? parseFloat(document.getElementById('walletAmount').value) || 0 : 0;
    const originalTotal = {{ totals.total_with_gst }};
    const newTotal = Math.max(0, originalTotal - walletAmount);
    
    // Update display
    document.getElementById('finalTotal').textContent = '₹' + newTotal.toFixed(2);
    document.getElementById('walletUsed').textContent = '₹' + walletAmount.toFixed(2);
}

function validateReferralCode() {
    const code = document.getElementById('referralCode').value.trim();
    if (!code) return;
    
    fetch('/api/referral/validate', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({code: code})
    })
    .then(res => res.json())
    .then(data => {
        const msgDiv = document.getElementById('referralMessage');
        if (data.valid) {
            msgDiv.innerHTML = `<div class="alert alert-success">
                Valid referral code from ${data.referrer_name}! 
                You'll get ${data.discount_percentage}% off on your first order.
            </div>`;
        } else {
            msgDiv.innerHTML = `<div class="alert alert-danger">${data.error}</div>`;
        }
    });
}
</script>
```

## Step 6: Update Login Template

Add referral code field to signup form in `templates/login.html`:

```html
<!-- Add this field in the signup form -->
<div class="form-group">
    <label for="referral_code">Referral Code (Optional)</label>
    <input type="text" class="form-control" id="referral_code" name="referral_code" 
           placeholder="Enter referral code if you have one">
    <small class="form-text text-muted">
        Get ₹500 signup bonus + extra benefits with a referral code!
    </small>
</div>
```

## Step 7: Update Profile Template

Add wallet section to `templates/profile.html`:

```html
<!-- Add this section in the profile page -->
<div class="card mb-4">
    <div class="card-header">
        <h4>Wallet & Referrals</h4>
    </div>
    <div class="card-body">
        <p><strong>Wallet Balance:</strong> ₹{{ "%.2f"|format(wallet_balance) }}</p>
        
        {% if referral_stats %}
        <p><strong>Your Referral Code:</strong> 
            <code>{{ referral_stats.coupon_code }}</code>
            <button onclick="copyReferralCode()" class="btn btn-sm btn-outline-primary">Copy</button>
        </p>
        <p><strong>Referral Earnings:</strong> ₹{{ "%.2f"|format(referral_stats.total_earnings) }}</p>
        {% endif %}
        
        <a href="{{ url_for('wallet_page') }}" class="btn btn-primary">View Wallet Details</a>
    </div>
</div>

{% if recent_transactions %}
<div class="card mb-4">
    <div class="card-header">
        <h5>Recent Transactions</h5>
    </div>
    <div class="card-body">
        <table class="table table-sm">
            <tbody>
                {% for txn in recent_transactions %}
                <tr>
                    <td>{{ txn.date }}</td>
                    <td>{{ txn.description }}</td>
                    <td class="{{ 'text-success' if txn.amount > 0 else 'text-danger' }}">
                        {{ "+" if txn.amount > 0 else "" }}₹{{ "%.2f"|format(txn.amount) }}
                    </td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        <a href="{{ url_for('wallet_page') }}" class="btn btn-sm btn-link">View All</a>
    </div>
</div>
{% endif %}

<script>
function copyReferralCode() {
    const code = "{{ referral_stats.coupon_code if referral_stats else '' }}";
    navigator.clipboard.writeText(code);
    alert('Referral code copied to clipboard!');
}
</script>
```

## Features Implemented

### ✅ Wallet System
- ₹500 signup bonus for all new users
- 5% cashback on first order
- Wallet balance tracking
- Transaction history
- Maximum ₹10,000 bonus usage per order

### ✅ Referral System
- Unique referral code for each user (based on username + user ID)
- 5% discount for referred users on first order
- 5% bonus for referrer when referred user makes first order
- 1-month expiry for referral codes
- Prevents self-referral and duplicate usage
- Referral statistics and earnings tracking

### ✅ Coupon System Integration
- Referral codes work as coupons
- Track coupon usage per user
- Prevent duplicate coupon usage
- Automatic expiry handling

## Testing Checklist

- [ ] Run database migration successfully
- [ ] New user signup credits ₹500 bonus
- [ ] Referral code validation works
- [ ] First order credits 5% cashback
- [ ] Referral bonus credited to both parties
- [ ] Wallet payment deduction works
- [ ] Transaction history displays correctly
- [ ] Bonus limit (₹10,000) enforced per order
- [ ] Coupon expiry works (1 month)
- [ ] Cannot use own referral code
- [ ] Cannot use same coupon twice

## Coupon Strategy Recommendations

Based on your requirements, here are recommended coupon strategies:

### 1. **Welcome Offers** (Already Implemented)
- ₹500 signup bonus
- 5% cashback on first order
- Encourages immediate purchase

### 2. **Referral Program** (Already Implemented)
- 5% for both parties
- Viral growth potential
- Limited to 10K usage per order prevents abuse

### 3. **Additional Coupon Ideas**

#### Seasonal/Festival Offers
```sql
-- Example: Diwali offer
INSERT INTO coupons (code, discount_type, discount_value, description, min_order_amount, max_discount_amount, valid_until)
VALUES ('DIWALI2026', 'percentage', 15, 'Diwali Special - 15% off', 5000, 2000, '2026-11-15');
```

#### Bulk Order Discounts
```sql
-- 10% off on orders above ₹20,000
INSERT INTO coupons (code, discount_type, discount_value, description, min_order_amount, max_discount_amount)
VALUES ('BULK10', 'percentage', 10, 'Bulk Order Discount', 20000, 5000);
```

#### Loyalty Rewards
```sql
-- For repeat customers
INSERT INTO coupons (code, discount_type, discount_value, description, usage_limit)
VALUES ('LOYAL500', 'fixed', 500, 'Loyalty Reward', 1);
```

### Cost-Benefit Analysis

**Current System Costs:**
- Signup bonus: ₹500 per user (one-time)
- First order cashback: 5% of order value (capped by ₹10K limit)
- Referral bonus: 5% × 2 = 10% of first order (capped by ₹10K limit)

**Maximum Loss Per Customer:**
- Signup: ₹500
- First order (₹50,000): ₹2,500 cashback + ₹2,500 referral = ₹5,000
- **Total Max: ₹5,500 per customer**

**Break-even:**
- Average order value: ₹15,000
- Profit margin: 30% = ₹4,500
- Need 2 orders to break even
- Referral brings 2 customers = 4 orders total
- **Net profit after bonuses: Positive**

### Recommendations to Minimize Loss

1. **Set minimum order values** for bonus usage
2. **Implement tier system**: Higher bonuses for higher order values
3. **Time-limited offers**: Create urgency
4. **Category-specific coupons**: Push slow-moving inventory
5. **Combo offers**: Bundle products for better margins

## Support

For issues or questions, check:
1. Database connection is working
2. All migrations ran successfully
3. wallet_system.py and wallet_routes.py are imported correctly
4. Templates are updated with wallet sections

## Next Steps

1. Run the database migration
2. Update main.py with the changes above
3. Create/update templates
4. Test all functionality
5. Monitor wallet transactions and adjust limits if needed