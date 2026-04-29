#!/bin/bash

# Fix Deals Display - Replace old banner and add discount pricing
# This script:
# 1. Replaces old banner with new professional deal banner
# 2. Removes old admin controls from purple bar
# 3. Updates product displays to show discounted prices

echo "🔧 Fixing Deals Display System..."

# Backup templates
echo "📦 Creating backups..."
mkdir -p backups_deals_$(date +%Y%m%d_%H%M%S)
cp templates/navbar.html backups_deals_$(date +%Y%m%d_%H%M%S)/
cp templates/index.html backups_deals_$(date +%Y%m%d_%H%M%S)/
cp templates/product_detail.html backups_deals_$(date +%Y%m%d_%H%M%S)/

echo "✅ Backups created"

# 1. Replace navbar.html - Remove old banner and admin controls, add new banner
echo "🎨 Updating navbar with professional deal banner..."
cat > templates/navbar.html << 'NAVBAR_EOF'
<!-- Professional Deal Banner -->
{% include 'deal_banner.html' %}

<nav class="custom-navbar navbar navbar-expand-md" aria-label="GSpaces Navigation Bar">
    <div class="container">
        <a class="navbar-brand" href="{{ url_for('index') }}">
            <img src="{{ url_for('static', filename='img/gspaces-logo.png') }}" alt="GSPACES-LOGO">
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarsFurni" aria-controls="navbarsFurni" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarsFurni">
            <ul class="custom-navbar-nav navbar-nav ms-auto mb-2 mb-md-0">
                <li class="nav-item {% if request.endpoint == 'index' %}active{% endif %}">
                    <a class="nav-link js-scroll-link" href="{{ url_for('index', section='home') }}" data-section="home">Home</a>
                </li>
                <li class="nav-item"><a class="nav-link js-scroll-link" href="{{ url_for('index', section='about') }}" data-section="about">About</a></li>
                <li class="nav-item"><a class="nav-link js-scroll-link" href="{{ url_for('index', section='corporate') }}" data-section="corporate">Corporate Tie-ups</a></li>
                <li class="nav-item"><a class="nav-link js-scroll-link" href="{{ url_for('index', section='products') }}" data-section="products">Setups</a></li>
                
                <li class="nav-item {% if request.endpoint == 'blogs' or request.endpoint == 'blog_detail' %}active{% endif %}">
                    <a class="nav-link" href="{{ url_for('blogs') }}">Blogs</a>
                </li>
                <li class="nav-item"><a class="nav-link js-scroll-link" href="{{ url_for('index', section='team') }}" data-section="team">Team</a></li>
                <li class="nav-item"><a class="nav-link js-scroll-link" href="{{ url_for('index', section='contact') }}" data-section="contact">Contact</a></li>
            </ul>
            <ul class="custom-navbar-cta navbar-nav mb-2 mb-md-0 ms-5">
                <li>
                    <a class="nav-link" href="{{ url_for('cart') }}">
                        <img src="{{ url_for('static', filename='img/desks.svg') }}" alt="Cart">
                        {% if cart_count > 0 %}
                            <span class="badge bg-primary rounded-pill">{{ cart_count }}</span>
                        {% endif %}
                    </a>
                </li>
                <li>
                    <a class="nav-link" href="{{ url_for('profile') }}">
                        <img src="{{ url_for('static', filename='img/user.svg') }}" alt="User">
                    </a>
                </li>
            </ul>
        </div>
    </div>
</nav>
<i class="mobile-nav-toggle"></i>

<!-- Chatbot CSS -->
<link rel="stylesheet" href="{{ url_for('static', filename='css/chatbot.css') }}">

<!-- Chatbot Float Button -->
<div class="chatbot-float-btn" id="chatbotFloatBtn" title="Chat with us!" style="cursor: pointer;">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
        <path d="M12 2C6.48 2 2 6.48 2 12c0 1.54.36 3 .97 4.29L2 22l5.71-.97C9 21.64 10.46 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm0 18c-1.38 0-2.68-.31-3.86-.85l-.28-.13-2.76.47.47-2.76-.13-.28C4.31 14.68 4 13.38 4 12c0-4.41 3.59-8 8-8s8 3.59 8 8-3.59 8-8 8z"/>
        <circle cx="9" cy="12" r="1.5"/>
        <circle cx="12" cy="12" r="1.5"/>
        <circle cx="15" cy="12" r="1.5"/>
    </svg>
</div>

<!-- Chatbot Modal -->
<div class="chatbot-modal" id="chatbotModal">
    <div class="chatbot-header">
        <h3>🤖 GSpaces Assistant</h3>
        <div style="display: flex; gap: 10px; align-items: center;">
            <button onclick="clearChatHistory()" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 6px 12px; border-radius: 15px; font-size: 12px; cursor: pointer; transition: background 0.3s;" onmouseover="this.style.background='rgba(255,255,255,0.3)'" onmouseout="this.style.background='rgba(255,255,255,0.2)'">🗑️ Clear</button>
            <button class="chatbot-close" id="chatbotClose">&times;</button>
        </div>
    </div>
    
    <div class="chatbot-messages" id="chatbotMessages">
        <div class="chatbot-message bot">
            <div class="message-bubble">
                Hello! 👋 I'm your GSpaces assistant. I can help you with:
                
                💰 Finding products within your budget
                🎫 Checking available coupons
                💳 Viewing your wallet balance
                📦 Tracking your orders
                📞 Getting contact information
                ℹ️ Learning about GSpaces
                
                How can I assist you today?
            </div>
            <div class="message-time" id="initialTime"></div>
            <div class="quick-replies" id="initialQuickReplies">
                <button class="quick-reply-btn" onclick="sendQuickReply('Show coupons')">🎫 Coupons</button>
                <button class="quick-reply-btn" onclick="sendQuickReply('Wallet balance')">💳 Wallet</button>
                <button class="quick-reply-btn" onclick="sendQuickReply('Products under 30k')">💰 Under 30k</button>
                <button class="quick-reply-btn" onclick="sendQuickReply('My orders')">📦 Orders</button>
                <button class="quick-reply-btn" onclick="sendQuickReply('Contact us')">📞 Contact</button>
            </div>
        </div>
    </div>
    
    <div class="chatbot-input-area">
        <input type="text" class="chatbot-input" id="chatbotInput" placeholder="Type your message...">
        <button class="chatbot-send-btn" id="chatbotSendBtn">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
            </svg>
        </button>
    </div>
</div>

<!-- Chatbot JavaScript -->
<script src="{{ url_for('static', filename='js/chatbot.js') }}"></script>
NAVBAR_EOF

echo "✅ Navbar updated with professional deal banner"

# 2. Create script to update index.html product display
echo "💰 Creating product display update script..."
cat > update_product_display.py << 'PYTHON_EOF'
import re

# Read index.html
with open('templates/index.html', 'r') as f:
    content = f.read()

# Find the product card section and update it to show discounts
# Look for the price display section around line 692
old_price_pattern = r'<p class="text-dark fw-semibold mb-1">₹ \{\{ product\.price \| inr \}\}</p>'

new_price_html = '''<!-- Price with discount -->
        {% set discount_info = product.get('discount_info', {}) %}
        {% if discount_info and discount_info.get('has_discount') %}
        <div class="mb-1">
          <span class="text-decoration-line-through text-muted me-2">₹{{ product.price | inr }}</span>
          <span class="text-success fw-bold">₹{{ discount_info.discounted_price | inr }}</span>
          <span class="badge bg-danger ms-1">{{ discount_info.discount_percent }}% OFF</span>
        </div>
        {% else %}
        <p class="text-dark fw-semibold mb-1">₹ {{ product.price | inr }}</p>
        {% endif %}'''

content = re.sub(old_price_pattern, new_price_html, content)

# Write back
with open('templates/index.html', 'w') as f:
    f.write(content)

print("✅ Updated index.html product display")
PYTHON_EOF

python3 update_product_display.py
rm update_product_display.py

# 3. Update product_detail.html to show discounts
echo "🛍️ Updating product detail page..."
cat > update_product_detail.py << 'PYTHON_EOF'
import re

# Read product_detail.html
with open('templates/product_detail.html', 'r') as f:
    content = f.read()

# Find the price section (around line 847-849) and update it
old_price_section = r'<div class="price">\s*<span class="price-currency">₹</span>\{\{ product\[\'price\'\]\|inr \}\}\s*</div>'

new_price_section = '''<div class="price">
            {% set discount_info = product.get('discount_info', {}) %}
            {% if discount_info and discount_info.get('has_discount') %}
              <div class="mb-2">
                <span class="text-decoration-line-through text-muted" style="font-size: 1.2rem;">₹{{ product['price']|inr }}</span>
              </div>
              <div>
                <span class="price-currency">₹</span>{{ discount_info.discounted_price|inr }}
                <span class="badge bg-danger ms-2" style="font-size: 0.9rem;">{{ discount_info.discount_percent }}% OFF</span>
              </div>
            {% else %}
              <span class="price-currency">₹</span>{{ product['price']|inr }}
            {% endif %}
          </div>'''

content = re.sub(old_price_section, new_price_section, content, flags=re.DOTALL)

# Write back
with open('templates/product_detail.html', 'w') as f:
    f.write(content)

print("✅ Updated product_detail.html")
PYTHON_EOF

python3 update_product_detail.py
rm update_product_detail.py

echo ""
echo "✅ All fixes applied successfully!"
echo ""
echo "📋 Changes made:"
echo "  1. ✅ Replaced old banner with professional deal banner"
echo "  2. ✅ Removed old admin controls from purple bar"
echo "  3. ✅ Updated product displays to show discounted prices"
echo ""
echo "🚀 Next steps:"
echo "  1. Commit and push changes:"
echo "     git add templates/"
echo "     git commit -m 'Replace old banner with professional deals system'"
echo "     git push origin deals-management-system"
echo ""
echo "  2. On server, pull and restart:"
echo "     cd /home/ec2-user/gspaces"
echo "     git pull origin deals-management-system"
echo "     sudo systemctl restart gspaces"
echo ""
echo "  3. Test the new banner and discounted prices!"
echo ""

# Made with Bob
