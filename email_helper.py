"""
Email Helper for GSpaces
Sends beautiful HTML emails for various notifications
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import render_template
import os

# Email configuration - Using same credentials as main.py
SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_USERNAME = os.getenv('MAIL_USERNAME', 'sri.chityala501@gmail.com')
SMTP_PASSWORD = os.getenv('MAIL_PASSWORD', 'zupd zixc vvzp kptk')
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
        
        # Send email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
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
        
        # Send email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Personal coupon email sent successfully to {user_email}")
        return True
        
    except Exception as e:
        print(f"❌ Error sending personal coupon email to {user_email}: {e}")
        return False


# Made with Bob