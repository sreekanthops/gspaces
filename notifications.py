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
                <a href="https://gspaces.in/admin/orders/view/{order_id}" 
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
    
    View order: https://gspaces.in/admin/orders/view/{order_id}
    """
    
    # Send email
    send_email_notification(ADMIN_EMAIL, subject, html_body, text_body)
    
    # WhatsApp notification to admin
    whatsapp_message = f"""🛒 *New Order #{order_id}*

👤 Customer: {customer_name}
📧 Email: {customer_email}
📦 Items: {items_count}
💰 Amount: ₹{total_amount}

View: https://gspaces.in/admin/orders/view/{order_id}"""
    
    if ADMIN_PHONE:
        send_whatsapp_notification(ADMIN_PHONE, whatsapp_message)


def notify_order_status_update(order_id, customer_name, customer_email, customer_phone, 
                               old_status, new_status, status_label):
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
    
    # Email notification to customer
    subject = f"{emoji} Order #{order_id} - {status_label}"
    
    html_body = f"""
    <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
            <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
                {emoji} Order Status Updated
            </h2>
            
            <p>Hi {customer_name},</p>
            
            <p>Your order status has been updated:</p>
            
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Order ID:</td>
                        <td style="padding: 8px 0;">#{order_id}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Status:</td>
                        <td style="padding: 8px 0; color: #27ae60; font-size: 16px; font-weight: bold;">
                            {emoji} {status_label}
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; font-weight: bold;">Updated:</td>
                        <td style="padding: 8px 0;">{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</td>
                    </tr>
                </table>
            </div>
            
            <p style="margin-top: 20px;">
                <a href="https://gspaces.in/order_details/{order_id}" 
                   style="display: inline-block; padding: 12px 24px; background-color: #3498db; color: white; 
                          text-decoration: none; border-radius: 5px; font-weight: bold;">
                    Track Your Order
                </a>
            </p>
            
            <p style="color: #7f8c8d; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 15px;">
                Thank you for shopping with GSpaces!<br>
                For any queries, contact us at support@gspaces.in
            </p>
        </div>
    </body>
    </html>
    """
    
    text_body = f"""
    Order Status Updated - GSpaces
    
    Hi {customer_name},
    
    Your order #{order_id} status has been updated to: {status_label}
    Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    
    Track your order: https://gspaces.in/order_details/{order_id}
    
    Thank you for shopping with GSpaces!
    """
    
    # Send email to customer
    send_email_notification(customer_email, subject, html_body, text_body)
    
    # WhatsApp notification to customer
    if customer_phone:
        whatsapp_message = f"""{emoji} *Order Status Update*

Order #{order_id}
Status: {status_label}

Track: https://gspaces.in/order_details/{order_id}

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
