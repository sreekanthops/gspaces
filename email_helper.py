"""
Email Helper for GSpaces
Sends beautiful HTML emails for various notifications
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import render_template
import os

# Email configuration - Hostinger Mail
SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.hostinger.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', '465'))  # Hostinger recommended port with SSL
SMTP_USERNAME = os.getenv('MAIL_USERNAME', 'sreekanth.chityala@gspaces.in')
SMTP_PASSWORD = os.getenv('MAIL_PASSWORD')  # Password from environment variable only
FROM_EMAIL = os.getenv('FROM_EMAIL', SMTP_USERNAME)
FROM_NAME = 'GSpaces Team'


def send_referral_update_email(user_email, user_name, referral_code, **kwargs):
    """
    Send a beautiful email when referral benefits or wallet balance is updated
    
    Args:
        user_email: Recipient email
        user_name: User's name
        referral_code: User's referral code
        **kwargs: Additional template variables:
            - wallet_adjustment: bool
            - new_wallet_balance: float
            - wallet_adjustment_reason: str
            - referral_benefits_updated: bool
            - friend_discount: str (e.g., "₹1000" or "10%")
            - owner_bonus: str (e.g., "₹1000" or "10%")
    """
    try:
        # Render the HTML template
        html_content = render_template(
            'email_referral_update.html',
            user_name=user_name,
            referral_code=referral_code,
            **kwargs
        )
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'🎉 Exciting Updates to Your GSpaces Rewards, {user_name}!'
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = user_email
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Send email using SSL (port 465)
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Email sent successfully to {user_email}")
        return True
        
    except Exception as e:
        print(f"❌ Error sending email to {user_email}: {e}")
        return False


def send_bulk_referral_update_email(users_data):
    """
    Send emails to multiple users about referral benefit updates
    
    Args:
        users_data: List of dicts with user info:
            [{
                'email': 'user@example.com',
                'name': 'User Name',
                'referral_code': 'CODE123',
                'friend_discount': '₹1000',
                'owner_bonus': '₹1000'
            }, ...]
    
    Returns:
        dict: {'success': count, 'failed': count}
    """
    success_count = 0
    failed_count = 0
    
    for user in users_data:
        result = send_referral_update_email(
            user_email=user['email'],
            user_name=user['name'],
            referral_code=user['referral_code'],
            referral_benefits_updated=True,
            friend_discount=user['friend_discount'],
            owner_bonus=user['owner_bonus']
        )
        
        if result:
            success_count += 1
        else:
            failed_count += 1
    
    return {'success': success_count, 'failed': failed_count}


def send_personal_coupon_email(user_email, user_name, coupon_code, discount, expiry_date, reason=None):
    """
    Send email notification when a personal coupon is created for a user
    
    Args:
        user_email: Recipient email
        user_name: User's name
        coupon_code: The personal coupon code
        discount: Discount amount (e.g., "₹500" or "10%")
        expiry_date: Expiry date string (e.g., "April 18, 2026")
        reason: Optional reason for the coupon
    """
    try:
        # Create HTML email content
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }}
                .coupon-box {{ background: white; border: 2px dashed #8b5cf6; padding: 20px; margin: 20px 0; text-align: center; border-radius: 8px; }}
                .coupon-code {{ font-size: 24px; font-weight: bold; color: #8b5cf6; font-family: monospace; letter-spacing: 2px; }}
                .discount {{ font-size: 32px; font-weight: bold; color: #10b981; margin: 10px 0; }}
                .info-box {{ background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; border-radius: 4px; }}
                .button {{ display: inline-block; background: #8b5cf6; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }}
                .footer {{ text-align: center; color: #6b7280; font-size: 12px; margin-top: 30px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎁 You've Received a Special Coupon!</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{user_name}</strong>,</p>
                    
                    <p>Great news! We've created a special coupon just for you!</p>
                    
                    {f'<p style="color: #6b7280; font-style: italic;">"{reason}"</p>' if reason else ''}
                    
                    <div class="coupon-box">
                        <div class="discount">{discount} OFF</div>
                        <p style="margin: 10px 0; color: #6b7280;">Your Personal Coupon Code:</p>
                        <div class="coupon-code">{coupon_code}</div>
                    </div>
                    
                    <div class="info-box">
                        <strong>⏰ Valid Until:</strong> {expiry_date}<br>
                        <strong>🎯 How to Use:</strong> Apply this code at checkout to get your discount!
                    </div>
                    
                    <p style="text-align: center;">
                        <a href="https://gspaces.in/cart" class="button">Shop Now →</a>
                    </p>
                    
                    <p style="color: #6b7280; font-size: 14px;">
                        This is a personal coupon created exclusively for you. Make sure to use it before it expires!
                    </p>
                </div>
                <div class="footer">
                    <p>© 2026 GSpaces. All rights reserved.</p>
                    <p>This is an automated email. Please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'🎁 Special Coupon Just for You, {user_name}!'
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = user_email
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Send email using SSL (port 465)
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Personal coupon email sent successfully to {user_email}")
        return True
        
    except Exception as e:
        print(f"❌ Error sending personal coupon email to {user_email}: {e}")
        return False


def send_professional_order_email(order_data):
    """
    Send professional order confirmation email with product images and pricing
    
    Args:
        order_data: Dictionary containing:
            - customer_name, customer_email, customer_phone
            - order_id, design_name, design_image
            - items: list of {name, quantity, price}
            - original_price, discount_percentage, discount_amount, final_price
            - delivery_address, comments
            - quotation_url
    """
    try:
        from flask import render_template, url_for
        
        # Prepare email data
        email_context = {
            'customer_name': order_data.get('customer_name'),
            'customer_phone': order_data.get('customer_phone'),
            'order_id': order_data.get('order_id'),
            'design_name': order_data.get('design_name', 'Custom Design'),
            'design_image': order_data.get('design_image'),
            'items': order_data.get('items', []),
            'original_price': order_data.get('original_price', 0),
            'discount_percentage': order_data.get('discount_percentage', 0),
            'discount_amount': order_data.get('discount_amount', 0),
            'final_price': order_data.get('final_price', 0),
            'delivery_address': order_data.get('delivery_address'),
            'comments': order_data.get('comments'),
            'quotation_url': order_data.get('quotation_url', 'https://gspaces.in'),
            'logo_url': 'https://gspaces.in/static/img/gspaces-logo.png',
            'company_email': 'sreekanth.chityala@gspaces.in',
            'company_phone': '+91-XXXXXXXXXX'
        }
        
        # Render HTML template
        html_content = render_template('email_professional_order.html', **email_context)
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'🎉 Order Confirmation #{order_data.get("order_id")} - GSpaces'
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = order_data.get('customer_email')
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Send email using SSL (port 465)
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Professional order email sent to {order_data.get('customer_email')}")
        return True
        
    except Exception as e:
        print(f"❌ Error sending professional order email: {e}")
        import traceback
        traceback.print_exc()
        return False


def send_admin_order_notification(customer_email, customer_name, customer_phone, order_id, 
                                  product_name, notification_type='order_created', **kwargs):
    """
    Send email notification for admin-created orders
    
    Args:
        customer_email: Customer's email address
        customer_name: Customer's name
        customer_phone: Customer's phone number
        order_id: Order ID
        product_name: Product/setup name
        notification_type: 'order_created' or 'status_update'
        **kwargs: Additional data (quantity, comments, old_status, new_status, etc.)
    """
    try:
        if notification_type == 'order_created':
            subject = f'Order Confirmation - #{order_id} | GSpaces'
            quantity = kwargs.get('quantity', 1)
            comments = kwargs.get('comments', '')
            total_amount = kwargs.get('total_amount', 0)
            
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .order-box {{ background: white; border: 2px solid #8b5cf6; padding: 20px; margin: 20px 0; border-radius: 8px; }}
                    .order-id {{ font-size: 24px; font-weight: bold; color: #8b5cf6; }}
                    .info-row {{ display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #e5e7eb; }}
                    .info-label {{ font-weight: bold; color: #6b7280; }}
                    .info-value {{ color: #111827; }}
                    .status-badge {{ display: inline-block; background: #fef3c7; color: #92400e; padding: 5px 15px; border-radius: 20px; font-size: 14px; }}
                    .button {{ display: inline-block; background: #8b5cf6; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }}
                    .footer {{ text-align: center; color: #6b7280; font-size: 12px; margin-top: 30px; }}
                    .highlight {{ background: #dbeafe; padding: 15px; border-left: 4px solid #3b82f6; margin: 20px 0; border-radius: 4px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🎉 Order Confirmation</h1>
                        <p style="margin: 10px 0; font-size: 18px;">Thank you for your order!</p>
                    </div>
                    <div class="content">
                        <p>Dear <strong>{customer_name}</strong>,</p>
                        
                        <p>We have received your order and our team will contact you shortly to confirm the details.</p>
                        
                        <div class="order-box">
                            <div style="text-align: center; margin-bottom: 20px;">
                                <div class="order-id">Order #{order_id}</div>
                                <span class="status-badge">Pending Confirmation</span>
                            </div>
                            
                            <div class="info-row">
                                <span class="info-label">Product:</span>
                                <span class="info-value">{product_name}</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Quantity:</span>
                                <span class="info-value">{quantity}</span>
                            </div>
                            {f'<div class="info-row"><span class="info-label">Total Amount:</span><span class="info-value">₹{total_amount:,.2f}</span></div>' if total_amount > 0 else ''}
                            <div class="info-row">
                                <span class="info-label">Contact Phone:</span>
                                <span class="info-value">{customer_phone}</span>
                            </div>
                        </div>
                        
                        {f'<div class="highlight"><strong>Your Comments:</strong><br>{comments}</div>' if comments else ''}
                        
                        <div style="background: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #374151;">📞 What's Next?</h3>
                            <ul style="color: #6b7280; margin: 10px 0;">
                                <li>Our team will call you at <strong>{customer_phone}</strong> to confirm order details</li>
                                <li>We'll discuss delivery timeline and any customization options</li>
                                <li>Payment details will be shared during confirmation</li>
                                <li>You'll receive updates via email as your order progresses</li>
                            </ul>
                        </div>
                        
                        <p style="text-align: center;">
                            <a href="https://gspaces.in/contact" class="button">Contact Us</a>
                        </p>
                        
                        <p style="color: #6b7280; font-size: 14px; text-align: center;">
                            For any questions, feel free to reach out to us!
                        </p>
                    </div>
                    <div class="footer">
                        <p><strong>GSpaces</strong> - Transform Your Space</p>
                        <p>📧 sreekanth.chityala@gspaces.in | 📞 +91-XXXXXXXXXX</p>
                        <p>© 2026 GSpaces. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
        elif notification_type == 'status_update':
            old_status = kwargs.get('old_status', '').replace('_', ' ').title()
            new_status = kwargs.get('new_status', '').replace('_', ' ').title()
            subject = f'Order Status Update - #{order_id} | GSpaces'
            
            # Status-specific messages
            status_messages = {
                'confirmed': '✅ Your order has been confirmed! We are preparing it for you.',
                'in_progress': '🔨 Your order is now in progress. Our team is working on it.',
                'ready_for_delivery': '📦 Great news! Your order is ready for delivery.',
                'out_for_delivery': '🚚 Your order is out for delivery and will reach you soon!',
                'delivered': '🎉 Your order has been delivered! We hope you love it.',
                'completed': '✨ Order completed! Thank you for choosing GSpaces.',
                'cancelled': '❌ Your order has been cancelled. Please contact us for details.',
                'on_hold': '⏸️ Your order is temporarily on hold. We will update you soon.'
            }
            
            status_key = kwargs.get('new_status', '').lower()
            status_message = status_messages.get(status_key, 'Your order status has been updated.')
            
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .status-update {{ background: white; border: 2px solid #10b981; padding: 25px; margin: 20px 0; border-radius: 8px; text-align: center; }}
                    .status-arrow {{ font-size: 24px; color: #6b7280; margin: 10px 0; }}
                    .old-status {{ color: #6b7280; text-decoration: line-through; }}
                    .new-status {{ color: #10b981; font-size: 24px; font-weight: bold; }}
                    .message-box {{ background: #dbeafe; padding: 20px; border-left: 4px solid #3b82f6; margin: 20px 0; border-radius: 4px; }}
                    .button {{ display: inline-block; background: #8b5cf6; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }}
                    .footer {{ text-align: center; color: #6b7280; font-size: 12px; margin-top: 30px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>📢 Order Status Update</h1>
                        <p style="margin: 10px 0;">Order #{order_id}</p>
                    </div>
                    <div class="content">
                        <p>Dear <strong>{customer_name}</strong>,</p>
                        
                        <p>Your order status has been updated:</p>
                        
                        <div class="status-update">
                            <div class="old-status">{old_status}</div>
                            <div class="status-arrow">↓</div>
                            <div class="new-status">{new_status}</div>
                        </div>
                        
                        <div class="message-box">
                            <p style="margin: 0; font-size: 16px;"><strong>{status_message}</strong></p>
                        </div>
                        
                        <div style="background: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #374151;">Order Details</h3>
                            <p style="margin: 5px 0;"><strong>Product:</strong> {product_name}</p>
                            <p style="margin: 5px 0;"><strong>Contact:</strong> {customer_phone}</p>
                        </div>
                        
                        <p style="text-align: center;">
                            <a href="https://gspaces.in/contact" class="button">Contact Us</a>
                        </p>
                        
                        <p style="color: #6b7280; font-size: 14px; text-align: center;">
                            If you have any questions, please don't hesitate to reach out!
                        </p>
                    </div>
                    <div class="footer">
                        <p><strong>GSpaces</strong> - Transform Your Space</p>
                        <p>📧 sreekanth.chityala@gspaces.in</p>
                        <p>© 2026 GSpaces. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """
        else:
            return False
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = customer_email
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Send email using SSL (port 465)
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Admin order notification sent to {customer_email}")
        return True
        
    except Exception as e:
        print(f"❌ Error sending admin order notification to {customer_email}: {e}")
        return False


# Made with Bob