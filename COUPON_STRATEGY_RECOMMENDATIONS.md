# Coupon Strategy & Recommendations for GSpaces

## Executive Summary

Based on your requirements and industry best practices, this document provides comprehensive coupon strategies that maximize customer acquisition while minimizing losses.

## Current Implementation (Wallet & Referral System)

### ✅ What's Already Implemented

1. **Signup Bonus**: ₹500 for every new user
2. **First Order Cashback**: 5% of order value (max ₹10,000 usage per order)
3. **Referral Program**: 
   - Referrer gets 5% bonus
   - Referred user gets 5% discount
   - Both on first order only
4. **Unique Referral Codes**: Auto-generated based on username
5. **1-Month Expiry**: Referral codes expire after 30 days
6. **Usage Limits**: ₹10,000 maximum bonus per order

## Cost Analysis

### Per Customer Acquisition Cost

| Component | Amount | Trigger | Frequency |
|-----------|--------|---------|-----------|
| Signup Bonus | ₹500 | Registration | One-time |
| First Order Cashback | 5% of order | First purchase | One-time |
| Referral Bonus (Referrer) | 5% of order | Referred user's first order | Per referral |
| Referral Discount (Referred) | 5% of order | First order | One-time |

### Example Scenarios

#### Scenario 1: Direct Customer (No Referral)
- Order Value: ₹20,000
- Signup Bonus: ₹500
- First Order Cashback: ₹1,000 (5%)
- **Total Cost: ₹1,500**
- **Cost %: 7.5% of order value**

#### Scenario 2: Referred Customer
- Order Value: ₹20,000
- Signup Bonus: ₹500
- First Order Discount: ₹1,000 (5%)
- First Order Cashback: ₹1,000 (5%)
- Referrer Bonus: ₹1,000 (5%)
- **Total Cost: ₹3,500**
- **Cost %: 17.5% of order value**
- **But brings 2 customers!**

### Break-Even Analysis

Assuming:
- Average Order Value: ₹15,000
- Gross Margin: 30% = ₹4,500
- Customer Lifetime Value: 3 orders

**Direct Customer:**
- First Order Cost: ₹1,500
- First Order Profit: ₹3,000
- Subsequent Orders: ₹4,500 × 2 = ₹9,000
- **Total Lifetime Profit: ₹12,000**

**Referred Customer (Both):**
- Total Acquisition Cost: ₹3,500
- Combined First Order Profit: ₹6,000 - ₹3,500 = ₹2,500
- Subsequent Orders: ₹9,000 × 2 = ₹18,000
- **Total Lifetime Profit: ₹20,500**

**Conclusion: Referral program is highly profitable!**

## Recommended Additional Coupon Strategies

### 1. Category-Specific Coupons

**Purpose**: Push specific product categories or clear inventory

```sql
-- Example: Office Chairs Special
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount, valid_until
)
VALUES (
    'CHAIR15', 'percentage', 15, 
    'Get 15% off on Office Chairs', 
    5000, 1500, 
    CURRENT_DATE + INTERVAL '15 days'
);
```

**Recommendation**: 
- 10-15% discount
- Minimum order: ₹5,000
- Max discount: ₹1,500
- Duration: 15 days
- **Expected Loss: 10-15% on category**
- **Expected Gain: 30-50% increase in category sales**

### 2. Bulk Order Discounts

**Purpose**: Encourage larger orders and B2B customers

```sql
-- Tier 1: Orders above ₹20,000
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount
)
VALUES (
    'BULK10', 'percentage', 10, 
    'Bulk Order Discount - 10% off on orders above ₹20,000', 
    20000, 3000
);

-- Tier 2: Orders above ₹50,000
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount
)
VALUES (
    'BULK15', 'percentage', 15, 
    'Bulk Order Discount - 15% off on orders above ₹50,000', 
    50000, 7500
);
```

**Recommendation**:
- Tier 1 (₹20K+): 10% off, max ₹3,000
- Tier 2 (₹50K+): 15% off, max ₹7,500
- **Expected Loss: 10-15% on bulk orders**
- **Expected Gain: Higher average order value, B2B customers**

### 3. Seasonal/Festival Offers

**Purpose**: Capitalize on high-demand periods

```sql
-- Diwali Special
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount, valid_until, usage_limit
)
VALUES (
    'DIWALI2026', 'percentage', 20, 
    'Diwali Special - 20% off on all orders', 
    10000, 3000, 
    '2026-11-15', 1000
);
```

**Recommendation**:
- Major Festivals: 15-20% off
- Minimum order: ₹10,000
- Max discount: ₹3,000
- Usage limit: 1000 customers
- **Expected Loss: 15-20% during festival**
- **Expected Gain: 200-300% increase in orders**

### 4. Loyalty Rewards

**Purpose**: Retain existing customers

```sql
-- For customers with 3+ orders
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, usage_limit
)
VALUES (
    'LOYAL500', 'fixed', 500, 
    'Thank you for being a loyal customer!', 
    5000, 1
);
```

**Recommendation**:
- Fixed ₹500 discount
- Minimum order: ₹5,000
- One-time use per customer
- Trigger: After 3rd order
- **Expected Loss: ₹500 per customer**
- **Expected Gain: Increased retention, higher LTV**

### 5. Cart Abandonment Recovery

**Purpose**: Recover lost sales

```sql
-- Send to users who abandoned cart
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount, valid_until
)
VALUES (
    'COMEBACK10', 'percentage', 10, 
    'We miss you! Get 10% off on your order', 
    3000, 1000, 
    CURRENT_DATE + INTERVAL '7 days'
);
```

**Recommendation**:
- 10% discount
- Minimum order: ₹3,000
- Max discount: ₹1,000
- Valid for 7 days
- **Expected Loss: 10% on recovered orders**
- **Expected Gain: 20-30% cart recovery rate**

### 6. Time-Limited Flash Sales

**Purpose**: Create urgency and boost sales

```sql
-- Weekend Flash Sale
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount, valid_until, usage_limit
)
VALUES (
    'FLASH24', 'percentage', 25, 
    '24-Hour Flash Sale - 25% off!', 
    8000, 2500, 
    CURRENT_TIMESTAMP + INTERVAL '24 hours', 500
);
```

**Recommendation**:
- 20-25% discount
- Minimum order: ₹8,000
- Max discount: ₹2,500
- Duration: 24-48 hours
- Usage limit: 500
- **Expected Loss: 20-25% on flash sale orders**
- **Expected Gain: Viral marketing, social media buzz**

### 7. Combo/Bundle Offers

**Purpose**: Increase average order value

```sql
-- Buy 2 Get 10% Off
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount
)
VALUES (
    'COMBO10', 'percentage', 10, 
    'Buy 2 or more items, get 10% off', 
    10000, 2000
);
```

**Recommendation**:
- 10% discount on multi-item orders
- Minimum order: ₹10,000
- Max discount: ₹2,000
- **Expected Loss: 10% on combo orders**
- **Expected Gain: Higher units per transaction**

## Smart Coupon Distribution Strategy

### 1. Email Marketing Segmentation

**New Users (0 orders):**
- Send: Signup bonus reminder + First order benefits
- Timing: Day 1, Day 3, Day 7
- Conversion Rate: 15-20%

**Active Users (1-2 orders):**
- Send: Loyalty rewards, category-specific offers
- Timing: Monthly
- Conversion Rate: 25-30%

**Dormant Users (No order in 60 days):**
- Send: Comeback offers, exclusive discounts
- Timing: Day 60, Day 90
- Conversion Rate: 10-15%

### 2. Social Media Campaigns

**Instagram/Facebook:**
- Share referral codes
- Flash sale announcements
- User-generated content with discount codes
- Expected Reach: 10,000+ per campaign

**WhatsApp:**
- Personalized offers
- Order updates with next purchase incentives
- Expected Open Rate: 70-80%

### 3. Influencer Partnerships

**Strategy:**
- Create unique codes for influencers
- Track performance per influencer
- Commission: 5-10% of sales

```sql
-- Influencer Coupon
INSERT INTO coupons (
    code, discount_type, discount_value, description, 
    min_order_amount, max_discount_amount
)
VALUES (
    'INFLUENCER15', 'percentage', 15, 
    'Exclusive discount from [Influencer Name]', 
    5000, 2000
);
```

## Coupon Abuse Prevention

### Already Implemented ✅
1. One-time use per user for referral codes
2. Expiry dates (1 month for referrals)
3. Maximum discount limits
4. Minimum order requirements

### Additional Recommendations

1. **IP Address Tracking**: Prevent multiple accounts from same IP
2. **Phone Verification**: Require phone verification for high-value coupons
3. **Order History Check**: Limit coupons based on order history
4. **Velocity Checks**: Flag accounts with suspicious activity

```python
# Add to wallet_system.py
def check_coupon_abuse(user_id, coupon_code):
    """Check for potential coupon abuse"""
    # Check if user has multiple accounts
    # Check order frequency
    # Check IP address patterns
    # Return True if suspicious
    pass
```

## ROI Optimization Tips

### 1. A/B Testing
- Test different discount percentages
- Test minimum order amounts
- Test coupon code names
- Measure conversion rates

### 2. Dynamic Pricing
- Adjust discounts based on inventory levels
- Higher discounts for slow-moving items
- Lower discounts for popular items

### 3. Personalization
- Send targeted offers based on browsing history
- Category-specific coupons for interested users
- Birthday/anniversary special offers

### 4. Gamification
- Spin-the-wheel for discount codes
- Scratch cards for surprise discounts
- Loyalty points system

## Monthly Coupon Calendar (Example)

| Week | Campaign | Discount | Expected Cost | Expected Revenue |
|------|----------|----------|---------------|------------------|
| 1 | New Month Sale | 15% | ₹50,000 | ₹3,00,000 |
| 2 | Category Focus | 10% | ₹30,000 | ₹2,00,000 |
| 3 | Flash Sale | 25% | ₹75,000 | ₹4,00,000 |
| 4 | Loyalty Rewards | ₹500 | ₹25,000 | ₹1,50,000 |
| **Total** | | | **₹1,80,000** | **₹10,50,000** |

**Net Revenue**: ₹8,70,000  
**Discount %**: 17.14%  
**Profit Margin** (assuming 30% gross): ₹1,35,000

## Key Metrics to Track

1. **Coupon Usage Rate**: % of customers using coupons
2. **Average Discount per Order**: Total discounts / Total orders
3. **Customer Acquisition Cost (CAC)**: Marketing spend / New customers
4. **Customer Lifetime Value (CLV)**: Average revenue per customer
5. **ROI**: (Revenue - Cost) / Cost × 100
6. **Referral Conversion Rate**: Referred users who purchase / Total referrals

## Recommended Monitoring Dashboard

```sql
-- Daily Coupon Performance Report
SELECT 
    c.code,
    c.discount_type,
    c.discount_value,
    COUNT(DISTINCT o.user_id) as users,
    COUNT(o.id) as orders,
    SUM(o.coupon_discount) as total_discount,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM coupons c
LEFT JOIN orders o ON c.code = o.coupon_code
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.code, c.discount_type, c.discount_value
ORDER BY total_revenue DESC;
```

## Final Recommendations

### DO's ✅
1. **Keep the current wallet & referral system** - It's well-designed
2. **Add seasonal campaigns** - 3-4 major festivals per year
3. **Implement bulk discounts** - Attract B2B customers
4. **Use email segmentation** - Personalized offers
5. **Track all metrics** - Data-driven decisions
6. **Test and optimize** - Continuous improvement

### DON'Ts ❌
1. **Don't offer blanket discounts** - Always have minimum order requirements
2. **Don't ignore abuse** - Monitor for suspicious activity
3. **Don't over-discount** - Maintain brand value
4. **Don't forget expiry dates** - Create urgency
5. **Don't neglect existing customers** - Loyalty is cheaper than acquisition

## Conclusion

Your current wallet and referral system is **excellent** and well-balanced. The ₹10,000 per order limit is smart and prevents excessive losses while still providing significant value to customers.

**Expected Overall Impact:**
- Customer Acquisition: +40-60%
- Average Order Value: +25-35%
- Customer Retention: +30-40%
- Marketing Cost: 15-20% of revenue
- Net Profit Impact: +10-15%

**Bottom Line**: With proper implementation and monitoring, this system should be **highly profitable** while providing excellent customer value.

## Support & Questions

For implementation help, refer to:
- `WALLET_INTEGRATION_GUIDE.md` - Technical integration
- `wallet_system.py` - Core functionality
- `wallet_routes.py` - API endpoints

Good luck with your implementation! 🚀