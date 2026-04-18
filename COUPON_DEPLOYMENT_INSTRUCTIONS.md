# Coupon System Deployment Instructions

## After Pulling the "offers" Branch

Follow these steps to deploy the coupon system on your server:

### Step 1: Pull the Branch
```bash
cd /path/to/gspaces
git fetch origin
git checkout offers
git pull origin offers
```

### Step 2: Run Database Migration
Execute the SQL script to create coupon tables and add sample coupons:

```bash
psql -U sri -d gspaces -f add_coupons_table.sql
```

**OR** if you need to specify host/password:

```bash
psql -U sri -h localhost -d gspaces -f add_coupons_table.sql
```

**OR** run the SQL directly:

```bash
psql -U sri -d gspaces << 'EOF'
-- Create coupons table
CREATE TABLE IF NOT EXISTS coupons (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2) NOT NULL,
    description TEXT,
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount_amount DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    usage_limit INTEGER,
    times_used INTEGER DEFAULT 0,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255)
);

-- Insert sample coupons
INSERT INTO coupons (code, discount_type, discount_value, description, min_order_amount, is_active, created_by)
VALUES 
    ('NEWGSPACES', 'percentage', 5.00, '5% discount for new customers', 0, TRUE, 'sri.chityala501@gmail.com'),
    ('DEEWALIFEST', 'percentage', 2.00, '2% Diwali festival discount', 0, TRUE, 'sri.chityala501@gmail.com'),
    ('DASARAFEST', 'fixed', 1000.00, '₹1000 off on Dasara festival', 0, TRUE, 'sri.chityala501@gmail.com')
ON CONFLICT (code) DO NOTHING;

-- Create coupon usage tracking table
CREATE TABLE IF NOT EXISTS coupon_usage (
    id SERIAL PRIMARY KEY,
    coupon_id INTEGER NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
    discount_applied DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(coupon_id, order_id)
);

-- Add coupon columns to orders table if they don't exist
ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_code VARCHAR(50);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_discount DECIMAL(10, 2) DEFAULT 0;
EOF
```

### Step 3: Restart the Application

**If using systemd:**
```bash
sudo systemctl restart gspaces
```

**If using supervisor:**
```bash
sudo supervisorctl restart gspaces
```

**If running manually:**
```bash
# Stop the current process (Ctrl+C or kill)
pkill -f "python main.py"

# Start again
cd /path/to/gspaces
python main.py
```

### Step 4: Verify Installation

1. **Check Database Tables:**
```bash
psql -U sri -d gspaces -c "\dt coupons"
psql -U sri -d gspaces -c "SELECT * FROM coupons;"
```

2. **Test Admin Panel:**
   - Login as: sri.chityala501@gmail.com
   - Visit: http://your-domain.com/admin/coupons
   - You should see the 3 sample coupons

3. **Test Customer Interface:**
   - Add items to cart
   - Go to cart page
   - Click "View Available Coupons" button
   - Try applying: NEWGSPACES, DEEWALIFEST, or DASARAFEST

### Step 5: Configure Nginx (if applicable)

No changes needed to nginx configuration. The routes are handled by Flask.

---

## Features Included

### Admin Features (sri.chityala501@gmail.com only):
- `/admin/coupons` - Manage all coupons
- Create new coupons with:
  - Code, discount type (percentage/fixed)
  - Discount value
  - Minimum order amount
  - Maximum discount cap
  - Usage limits
  - Expiry dates
- Activate/Deactivate coupons
- Delete coupons
- View usage statistics

### Customer Features:
- Coupon input field in cart
- "View Available Coupons" popup modal
- Click to apply coupons
- Real-time discount calculation
- Shows savings amount
- Applied coupon display with remove option

### Sample Coupons:
1. **NEWGSPACES** - 5% discount
2. **DEEWALIFEST** - 2% discount
3. **DASARAFEST** - ₹1000 flat discount

---

## Troubleshooting

### If tables already exist:
```bash
# Check if tables exist
psql -U sri -d gspaces -c "\dt coupons"

# If they exist but need to be recreated:
psql -U sri -d gspaces -c "DROP TABLE IF EXISTS coupon_usage CASCADE;"
psql -U sri -d gspaces -c "DROP TABLE IF EXISTS coupons CASCADE;"

# Then run the migration script again
psql -U sri -d gspaces -f add_coupons_table.sql
```

### If coupons don't show up:
```bash
# Verify coupons in database
psql -U sri -d gspaces -c "SELECT code, discount_type, discount_value, is_active FROM coupons;"

# Check if they're active
psql -U sri -d gspaces -c "UPDATE coupons SET is_active = TRUE;"
```

### If admin panel shows 403:
- Ensure you're logged in as sri.chityala501@gmail.com
- Check ADMIN_EMAILS in main.py includes your email

---

## Files Changed/Added

### New Files:
- `add_coupons_table.sql` - Database migration script
- `templates/admin_coupons.html` - Admin management interface
- `templates/cart_with_coupons.html` - Enhanced cart template
- `templates/cart_backup.html` - Backup of original cart
- `COUPON_DEPLOYMENT_INSTRUCTIONS.md` - This file

### Modified Files:
- `main.py` - Added coupon routes and logic
- `templates/cart.html` - Replaced with coupon-enabled version

---

## Support

If you encounter any issues:
1. Check application logs
2. Verify database connection
3. Ensure all tables were created successfully
4. Restart the application

For questions, contact the development team.