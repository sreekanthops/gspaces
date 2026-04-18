"""
Email Helper for GSpaces
Sends beautiful HTML emails for various notifications
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import render_template
import os

# Email configuration
SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_USERNAME = os.getenv('SMTP_USERNAME', 'your-email@gmail.com')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', 'your-app-password')
FROM_EMAIL = os.getenv('FROM_EMAIL', 'noreply@gspaces.in')
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


# Made with Bob