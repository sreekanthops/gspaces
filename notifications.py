"""
Notification System for GSpaces
Handles email and WhatsApp notifications for orders
"""

import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import requests
from datetime import datetime

# Configuration from environment variables
ADMIN_EMAIL = os.getenv('ADMIN_EMAIL', 'sri.chityala501@gmail.com')
ADMIN_PHONE = os.getenv('ADMIN_PHONE', '+917075077384')  # WhatsApp number with country code
APP_BASE_URL = os.getenv('APP_BASE_URL', 'http://13.51.205.239')  # Base URL for links in emails

# Email Configuration (using existing MAIL_ variables from main.py)
SMTP_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('MAIL_PORT', '587'))
SMTP_USERNAME = os.getenv('MAIL_USERNAME', 'sri.chityala501@gmail.com')
SMTP_PASSWORD = os.getenv('MAIL_PASSWORD', 'zupd zixc vvzp kptk')
SMTP_FROM_EMAIL = os.getenv('MAIL_DEFAULT_SENDER', SMTP_USERNAME)

# WhatsApp Configuration (using CallMeBot - Free service)
# Alternative: Twilio WhatsApp Sandbox (requires account)
WHATSAPP_API_KEY = os.getenv('WHATSAPP_API_KEY', '')  # CallMeBot API key
ENABLE_EMAIL = os.getenv('ENABLE_EMAIL_NOTIFICATIONS', 'true').lower() == 'true'
ENABLE_WHATSAPP = os.getenv('ENABLE_WHATSAPP_NOTIFICATIONS', 'false').lower() == 'true'


def send_email_notification(to_email, subject, html_body, text_body=None):
    """
    Send email notification
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        html_body: HTML content of email
        text_body: Plain text fallback (optional)
    
    Returns:
        bool: True if sent successfully, False otherwise
    """
    if not ENABLE_EMAIL or not SMTP_USERNAME or not SMTP_PASSWORD:
        print("Email notifications disabled or not configured")
        return False
    
    try:
        msg = MIMEMultipart('alternative')
        msg['From'] = SMTP_FROM_EMAIL
        msg['To'] = to_email
        msg['Subject'] = subject
        
        # Add text and HTML parts
        if text_body:
            part1 = MIMEText(text_body, 'plain')
            msg.attach(part1)
        
        part2 = MIMEText(html_body, 'html')
        msg.attach(part2)
        
        # Send email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"Email sent successfully to {to_email}")
        return True
    
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


def send_whatsapp_notification(phone_number, message):
    """
    Send WhatsApp notification using CallMeBot API (Free)
    
    To get API key:
    1. Add phone number +34 644 44 71 67 to contacts as "CallMeBot"
    2. Send message "I allow callmebot to send me messages" to this contact
    3. You'll receive your API key
    
    Args:
        phone_number: Phone number with country code (e.g., +919876543210)
        message: Message text
    
    Returns:
        bool: True if sent successfully, False otherwise
    """
    if not ENABLE_WHATSAPP or not WHATSAPP_API_KEY:
        print("WhatsApp notifications disabled or not configured")
        return False
    
    try:
        # CallMeBot API endpoint
        url = "https://api.callmebot.com/whatsapp.php"
        
        # Remove + from phone number if present
        phone = phone_number.replace('+', '')
        
        params = {
            'phone': phone,
            'text': message,
            'apikey': WHATSAPP_API_KEY
        }
        
        response = requests.get(url, params=params)
        
        if response.status_code == 200:
            print(f"WhatsApp message sent successfully to {phone_number}")
            return True
        else:
            print(f"Failed to send WhatsApp message: {response.text}")
            return False
    
    except Exception as e:
        print(f"Error sending WhatsApp message: {e}")
        return False


def notify_new_order(order_id, customer_name, customer_email, total_amount, items_count):
    """
    Notify admin about new order
    
    Args:
        order_id: Order ID
        customer_name: Customer name
        customer_email: Customer email
        total_amount: Order total amount
        items_count: Number of items
    """
    # Email notification to admin
    subject = f"🛒 New Order #{order_id} - GSpaces"
    
    html_body = f"""
    <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
            <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
                🎉 New Order Received!
            </h2>
            
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <h3 style="margin-top: 0; color: #2c3e50;">Order Details</h3>
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Order ID:</td>
                        <td style="padding: 8px 0;">#{order_id}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Customer:</td>
                        <td style="padding: 8px 0;">{customer_name}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Email:</td>
                        <td style="padding: 8px 0;">{customer_email}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Items:</td>
                        <td style="padding: 8px 0;">{items_count} item(s)</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Total Amount:</td>
                        <td style="padding: 8px 0; color: #27ae60; font-size: 18px; font-weight: bold;">₹{total_amount}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Time:</td>
                        <td style="padding: 8px 0;">{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</td>
                    </tr>
                </table>
            </div>
            
            <p style="margin-top: 20px;">
                <a href="{APP_BASE_URL}/admin/orders/view/{order_id}"
                   style="display: inline-block; padding: 12px 24px; background-color: #3498db; color: white; 
                          text-decoration: none; border-radius: 5px; font-weight: bold;">
                    View Order Details
                </a>
            </p>
            
            <p style="color: #7f8c8d; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 15px;">
                This is an automated notification from GSpaces Order Management System.
            </p>
        </div>
    </body>
    </html>
    """
    
    text_body = f"""
    New Order Received - GSpaces
    
    Order ID: #{order_id}
    Customer: {customer_name}
    Email: {customer_email}
    Items: {items_count} item(s)
    Total Amount: ₹{total_amount}
    Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    
    View order: {APP_BASE_URL}/admin/orders/view/{order_id}
    """
    
    # Send email
    send_email_notification(ADMIN_EMAIL, subject, html_body, text_body)
    
    # WhatsApp notification to admin
    whatsapp_message = f"""🛒 *New Order #{order_id}*

👤 Customer: {customer_name}
📧 Email: {customer_email}
📦 Items: {items_count}
💰 Amount: ₹{total_amount}

View: {APP_BASE_URL}/admin/orders/view/{order_id}"""
    
    if ADMIN_PHONE:
        send_whatsapp_notification(ADMIN_PHONE, whatsapp_message)


def _get_delivery_timeline_html(status):
    """Generate delivery timeline HTML based on status"""
    if status in ['shipped', 'out_for_delivery']:
        return """
        <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="margin: 0; color: #856404; font-weight: 600;">
                🚚 Your order is on its way!
            </p>
            <p style="margin: 10px 0 0 0; color: #856404; font-size: 14px;">
                Expected delivery within 2-3 business days.
            </p>
        </div>
        """
    elif status == 'delivered':
        return """
        <div style="background-color: #d4edda; border-left: 4px solid #28a745; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="margin: 0; color: #155724; font-weight: 600;">
                🎉 Your order has been delivered!
            </p>
            <p style="margin: 10px 0 0 0; color: #155724; font-size: 14px;">
                We hope you enjoy your purchase. Please rate your experience!
            </p>
        </div>
        """
    return ""


def notify_order_status_update(order_id, customer_name, customer_email, customer_phone,
                               old_status, new_status, status_label, order_items=None, total_amount=None):
    """
    Notify customer about order status update
    
    Args:
        order_id: Order ID
        customer_name: Customer name
        customer_email: Customer email
        customer_phone: Customer phone number
        old_status: Previous status code
        new_status: New status code
        status_label: Human-readable status label
        order_items: List of order items (optional)
        total_amount: Total order amount (optional)
    """
    # Status emojis
    status_emojis = {
        'placed': '📝',
        'confirmed': '✅',
        'packed': '📦',
        'shipped': '🚚',
        'out_for_delivery': '🏃',
        'delivered': '🎉',
        'cancelled': '❌'
    }
    
    emoji = status_emojis.get(new_status, '📋')
    
    # Build order items HTML if provided
    items_html = ""
    if order_items and len(order_items) > 0:
        items_rows = ""
        for item in order_items:
            items_rows += f"""
            <tr style="border-bottom: 1px solid #e5e7eb;">
                <td style="padding: 12px 8px;">
                    <strong>{item.get('product_name', 'Product')}</strong>
                </td>
                <td style="padding: 12px 8px; text-align: center;">{item.get('quantity', 1)}</td>
                <td style="padding: 12px 8px; text-align: right;">₹{item.get('price_at_purchase', 0)}</td>
            </tr>
            """
        
        items_html = f"""
        <div style="margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-bottom: 15px;">Order Items</h3>
            <table style="width: 100%; border-collapse: collapse; background: white; border: 1px solid #e5e7eb; border-radius: 8px;">
                <thead>
                    <tr style="background-color: #f8f9fa; border-bottom: 2px solid #e5e7eb;">
                        <th style="padding: 12px 8px; text-align: left;">Product</th>
                        <th style="padding: 12px 8px; text-align: center;">Qty</th>
                        <th style="padding: 12px 8px; text-align: right;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_rows}
                </tbody>
            </table>
        </div>
        """
    
    # Build total amount section if provided
    total_html = ""
    if total_amount:
        total_html = f"""
        <div style="background-color: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: right;">
            <span style="font-size: 18px; font-weight: bold; color: #2c3e50;">Total Amount: </span>
            <span style="font-size: 24px; font-weight: bold; color: #27ae60;">₹{total_amount}</span>
        </div>
        """
    
    # Email notification to customer
    subject = f"{emoji} Order #{order_id} - {status_label}"
    
    html_body = f"""
    <html>
    <head>
        <style>
            @media only screen and (max-width: 600px) {{
                .container {{ padding: 10px !important; }}
                .button {{ width: 100% !important; }}
            }}
        </style>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 20px auto; background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px 20px; text-align: center;">
                <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 600;">
                    {emoji} Order Status Update
                </h1>
                <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">
                    GSpaces - Premium Office Furniture
                </p>
            </div>
            
            <!-- Content -->
            <div class="container" style="padding: 30px 20px;">
                <p style="font-size: 16px; color: #333; margin: 0 0 20px 0;">Hi <strong>{customer_name}</strong>,</p>
                
                <p style="font-size: 15px; color: #666; line-height: 1.6; margin: 0 0 25px 0;">
                    Great news! Your order status has been updated. Here are the details:
                </p>
                
                <!-- Status Card -->
                <div style="background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); padding: 20px; border-radius: 10px; margin: 20px 0;">
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                            <td style="padding: 10px 0; font-weight: 600; color: #555; font-size: 14px;">Order ID:</td>
                            <td style="padding: 10px 0; text-align: right; color: #333; font-size: 16px; font-weight: 600;">
                                #{order_id}
                            </td>
                        </tr>
                        <tr>
                            <td style="padding: 10px 0; font-weight: 600; color: #555; font-size: 14px;">Current Status:</td>
                            <td style="padding: 10px 0; text-align: right;">
                                <span style="background-color: #27ae60; color: white; padding: 6px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; display: inline-block;">
                                    {emoji} {status_label}
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding: 10px 0; font-weight: 600; color: #555; font-size: 14px;">Updated At:</td>
                            <td style="padding: 10px 0; text-align: right; color: #666; font-size: 14px;">
                                {datetime.now().strftime('%d %b %Y, %I:%M %p')}
                            </td>
                        </tr>
                    </table>
                </div>
                
                <!-- Order Items -->
                {items_html}
                
                <!-- Total Amount -->
                {total_html}
                
                <!-- Action Buttons -->
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{APP_BASE_URL}/profile"
                       class="button"
                       style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                              color: white; text-decoration: none; border-radius: 25px; font-weight: 600; font-size: 16px;
                              box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4); transition: all 0.3s ease;">
                        📦 Track Your Order
                    </a>
                </div>
                
                <!-- Delivery Timeline (for certain statuses) -->
                {_get_delivery_timeline_html(new_status)}
                
                <!-- Support Section -->
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; margin-top: 30px; text-align: center;">
                    <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">Need help with your order?</p>
                    <p style="margin: 0;">
                        <a href="mailto:support@gspaces.in" style="color: #667eea; text-decoration: none; font-weight: 600;">
                            📧 support@gspaces.in
                        </a>
                        <span style="color: #ccc; margin: 0 10px;">|</span>
                        <a href="tel:+917075077384" style="color: #667eea; text-decoration: none; font-weight: 600;">
                            📞 +91 707 507 7384
                        </a>
                    </p>
                </div>
            </div>
            
            <!-- Footer -->
            <div style="background-color: #2c3e50; padding: 20px; text-align: center;">
                <p style="color: rgba(255,255,255,0.8); margin: 0 0 10px 0; font-size: 14px;">
                    Thank you for choosing GSpaces!
                </p>
                <p style="color: rgba(255,255,255,0.6); margin: 0; font-size: 12px;">
                    © 2026 GSpaces. Premium Office Furniture Solutions.
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    text_body = f"""
    Order Status Updated - GSpaces
    
    Hi {customer_name},
    
    Your order #{order_id} status has been updated to: {status_label}
    Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    
    Track your order: {APP_BASE_URL}/profile
    
    Thank you for shopping with GSpaces!
    """
    
    # Send email to customer
    send_email_notification(customer_email, subject, html_body, text_body)
    
    # WhatsApp notification to customer
    if customer_phone:
        whatsapp_message = f"""{emoji} *Order Status Update*

Order #{order_id}
Status: {status_label}

Track: {APP_BASE_URL}/profile

Thank you for shopping with GSpaces! 🛍️"""
        
        send_whatsapp_notification(customer_phone, whatsapp_message)
    
    # Also notify admin
    admin_subject = f"Order #{order_id} Status Updated to {status_label}"
    admin_html = f"""
    <html>
    <body style="font-family: Arial, sans-serif;">
        <p>Order #{order_id} status updated:</p>
        <ul>
            <li>Customer: {customer_name} ({customer_email})</li>
            <li>Old Status: {old_status}</li>
            <li>New Status: {new_status} - {status_label}</li>
            <li>Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</li>
        </ul>
    </body>
    </html>
    """
    
    send_email_notification(ADMIN_EMAIL, admin_subject, admin_html)


def send_custom_email_to_customer(customer_email, customer_name, order_id, subject, message):
    """
    Send custom email to customer from admin
    
    Args:
        customer_email: Customer email address
        customer_name: Customer name
        order_id: Order ID
        subject: Email subject
        message: Custom message from admin
    
    Returns:
        bool: True if sent successfully, False otherwise
    """
    html_body = f"""
    <html>
    <head>
        <style>
            @media only screen and (max-width: 600px) {{
                .container {{ padding: 10px !important; }}
            }}
        </style>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 20px auto; background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px 20px; text-align: center;">
                <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 600;">
                    📧 Message from GSpaces
                </h1>
                <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">
                    Regarding Order #{order_id}
                </p>
            </div>
            
            <!-- Content -->
            <div class="container" style="padding: 30px 20px;">
                <p style="font-size: 16px; color: #333; margin: 0 0 20px 0;">Hi <strong>{customer_name}</strong>,</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; border-left: 4px solid #667eea; margin: 20px 0;">
                    <p style="margin: 0; color: #333; line-height: 1.6; white-space: pre-wrap;">{message}</p>
                </div>
                
                <!-- Order Link -->
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{APP_BASE_URL}/profile"
                       style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                              color: white; text-decoration: none; border-radius: 25px; font-weight: 600; font-size: 16px;
                              box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                        View Order Details
                    </a>
                </div>
                
                <!-- Support Section -->
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px; margin-top: 30px; text-align: center;">
                    <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">Need further assistance?</p>
                    <p style="margin: 0;">
                        <a href="mailto:support@gspaces.in" style="color: #667eea; text-decoration: none; font-weight: 600;">
                            📧 support@gspaces.in
                        </a>
                        <span style="color: #ccc; margin: 0 10px;">|</span>
                        <a href="tel:+917075077384" style="color: #667eea; text-decoration: none; font-weight: 600;">
                            📞 +91 707 507 7384
                        </a>
                    </p>
                </div>
            </div>
            
            <!-- Footer -->
            <div style="background-color: #2c3e50; padding: 20px; text-align: center;">
                <p style="color: rgba(255,255,255,0.8); margin: 0 0 10px 0; font-size: 14px;">
                    Thank you for choosing GSpaces!
                </p>
                <p style="color: rgba(255,255,255,0.6); margin: 0; font-size: 12px;">
                    © 2026 GSpaces. Premium Office Furniture Solutions.
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    text_body = f"""
    Message from GSpaces - Order #{order_id}
    
    Hi {customer_name},
    
    {message}
    
    View your order: {APP_BASE_URL}/profile
    
    For assistance, contact us at support@gspaces.in or +91 707 507 7384
    
    Thank you for choosing GSpaces!
    """
    
    return send_email_notification(customer_email, subject, html_body, text_body)


def test_notifications():
    """
    Test notification system
    """
    print("\n=== Testing Notification System ===\n")
    
    print("1. Testing Email Notification...")
    email_result = send_email_notification(
        ADMIN_EMAIL,
        "Test Email - GSpaces Notifications",
        "<h1>Test Email</h1><p>This is a test email from GSpaces notification system.</p>",
        "Test Email\n\nThis is a test email from GSpaces notification system."
    )
    print(f"Email test result: {'✅ Success' if email_result else '❌ Failed'}\n")
    
    if ADMIN_PHONE:
        print("2. Testing WhatsApp Notification...")
        whatsapp_result = send_whatsapp_notification(
            ADMIN_PHONE,
            "🧪 Test message from GSpaces notification system"
        )
        print(f"WhatsApp test result: {'✅ Success' if whatsapp_result else '❌ Failed'}\n")
    else:
        print("2. WhatsApp test skipped (ADMIN_PHONE not configured)\n")
    
    print("=== Test Complete ===\n")


if __name__ == "__main__":
    # Run tests when executed directly
    test_notifications()

# Made with Bob
