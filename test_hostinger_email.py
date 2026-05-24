#!/usr/bin/env python3
"""
Test script for Hostinger email configuration
Tests both email_helper.py and Flask-Mail setup
Password is loaded from environment variable for security
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

# Hostinger Mail Configuration (SSL on port 465)
SMTP_SERVER = 'smtp.hostinger.com'
SMTP_PORT = 465
SMTP_USERNAME = 'sreekanth.chityala@gspaces.in'
SMTP_PASSWORD = os.getenv('MAIL_PASSWORD')  # Password from environment variable
FROM_EMAIL = 'sreekanth.chityala@gspaces.in'
FROM_NAME = 'GSpaces Team'

def check_password():
    """Check if password is set in environment"""
    if not SMTP_PASSWORD:
        print("=" * 60)
        print("❌ ERROR: MAIL_PASSWORD not set!")
        print("=" * 60)
        print("\nPlease set the password environment variable:")
        print("  export MAIL_PASSWORD='your_password_here'")
        print("\nOr run the script with:")
        print("  MAIL_PASSWORD='your_password' python test_hostinger_email.py")
        return False
    print("✓ Password loaded from environment variable")
    return True


def test_basic_smtp():
    """Test basic SMTP connection and email sending"""
    print("\n" + "=" * 60)
    print("Testing Hostinger SMTP Connection...")
    print("=" * 60)
    
    if not check_password():
        return False
    
    try:
        # Create test message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = '🧪 Test Email - Hostinger Integration'
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = SMTP_USERNAME  # Send to self for testing
        
        # HTML content
        html_content = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                         color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }}
                .success {{ background: #d1fae5; border-left: 4px solid #10b981; padding: 15px; 
                          margin: 20px 0; color: #065f46; border-radius: 4px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>✅ Hostinger Mail Integration Test</h1>
                </div>
                <div class="content">
                    <h2>Success!</h2>
                    <p>This is a test email from your GSpaces application using Hostinger mail.</p>
                    
                    <div class="success">
                        <strong>✓ SMTP Connection:</strong> Working<br>
                        <strong>✓ Email Sending:</strong> Successful<br>
                        <strong>✓ Server:</strong> {smtp_server}<br>
                        <strong>✓ Port:</strong> {smtp_port}
                    </div>
                    
                    <p>Your Hostinger mail integration is configured correctly!</p>
                    
                    <p style="color: #6b7280; font-size: 14px; margin-top: 30px;">
                        <strong>Configuration Details:</strong><br>
                        From: {from_email}<br>
                        Server: {smtp_server}<br>
                        Port: {smtp_port}
                    </p>
                </div>
            </div>
        </body>
        </html>
        """.format(
            from_email=FROM_EMAIL,
            smtp_server=SMTP_SERVER,
            smtp_port=SMTP_PORT
        )
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Connect and send using SSL
        print(f"Connecting to {SMTP_SERVER}:{SMTP_PORT} with SSL...")
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            print("✓ Connected to SMTP server with SSL encryption")
            
            print(f"Logging in as {SMTP_USERNAME}...")
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            print("✓ Authentication successful")
            
            print(f"Sending test email to {SMTP_USERNAME}...")
            server.send_message(msg)
            print("✓ Email sent successfully")
        
        print("\n" + "=" * 60)
        print("✅ SUCCESS! Hostinger mail is working correctly!")
        print("=" * 60)
        print(f"\nCheck your inbox at: {SMTP_USERNAME}")
        print("The test email should arrive within a few seconds.")
        return True
        
    except smtplib.SMTPAuthenticationError as e:
        print("\n" + "=" * 60)
        print("❌ AUTHENTICATION FAILED")
        print("=" * 60)
        print(f"Error: {e}")
        print("\nPossible issues:")
        print("1. Incorrect password")
        print("2. Email account not activated")
        print("3. SMTP access not enabled in Hostinger")
        return False
        
    except smtplib.SMTPConnectError as e:
        print("\n" + "=" * 60)
        print("❌ CONNECTION FAILED")
        print("=" * 60)
        print(f"Error: {e}")
        print("\nPossible issues:")
        print("1. Incorrect SMTP server or port")
        print("2. Firewall blocking connection")
        print("3. Network connectivity issues")
        return False
        
    except Exception as e:
        print("\n" + "=" * 60)
        print("❌ ERROR OCCURRED")
        print("=" * 60)
        print(f"Error: {e}")
        print(f"Error type: {type(e).__name__}")
        return False


def test_flask_mail():
    """Test Flask-Mail configuration"""
    print("\n" + "=" * 60)
    print("Testing Flask-Mail Configuration...")
    print("=" * 60)
    
    if not SMTP_PASSWORD:
        print("❌ Cannot test: Password not set")
        return False
    
    try:
        from flask import Flask
        from flask_mail import Mail, Message
        
        # Create test Flask app
        app = Flask(__name__)
        app.config['MAIL_SERVER'] = SMTP_SERVER
        app.config['MAIL_PORT'] = SMTP_PORT
        app.config['MAIL_USE_SSL'] = True
        app.config['MAIL_USE_TLS'] = False
        app.config['MAIL_USERNAME'] = SMTP_USERNAME
        app.config['MAIL_PASSWORD'] = SMTP_PASSWORD
        app.config['MAIL_DEFAULT_SENDER'] = FROM_EMAIL
        
        mail = Mail(app)
        
        with app.app_context():
            msg = Message(
                '🧪 Flask-Mail Test - Hostinger',
                recipients=[SMTP_USERNAME]
            )
            msg.html = """
            <h2>Flask-Mail Test Successful!</h2>
            <p>Your Flask-Mail configuration with Hostinger is working correctly.</p>
            <p><strong>Server:</strong> smtp.hostinger.com</p>
            <p><strong>Port:</strong> 587</p>
            """
            
            print("Sending test email via Flask-Mail...")
            mail.send(msg)
            print("✓ Flask-Mail test email sent successfully")
        
        print("\n" + "=" * 60)
        print("✅ Flask-Mail configuration is working!")
        print("=" * 60)
        return True
        
    except ImportError:
        print("⚠️  Flask-Mail not installed. Skipping Flask-Mail test.")
        print("Install with: pip install Flask-Mail")
        return None
        
    except Exception as e:
        print(f"❌ Flask-Mail test failed: {e}")
        return False


def main():
    """Run all tests"""
    print("\n" + "🚀 " * 20)
    print("HOSTINGER EMAIL INTEGRATION TEST")
    print("🚀 " * 20 + "\n")
    
    print("Configuration:")
    print(f"  Server: {SMTP_SERVER}")
    print(f"  Port: {SMTP_PORT}")
    print(f"  Username: {SMTP_USERNAME}")
    print(f"  From: {FROM_EMAIL}")
    
    # Test 1: Basic SMTP
    smtp_result = test_basic_smtp()
    
    # Test 2: Flask-Mail (optional)
    flask_result = test_flask_mail() if smtp_result else None
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print(f"Basic SMTP Test: {'✅ PASSED' if smtp_result else '❌ FAILED'}")
    if flask_result is not None:
        print(f"Flask-Mail Test: {'✅ PASSED' if flask_result else '❌ FAILED'}")
    else:
        print(f"Flask-Mail Test: ⚠️  SKIPPED")
    print("=" * 60)
    
    if smtp_result:
        print("\n✅ Your Hostinger mail integration is ready to use!")
        print("\nNext steps:")
        print("1. Check your email inbox for test messages")
        print("2. Set MAIL_PASSWORD in production environment")
        print("3. Test OTP emails in your application")
        print("4. Test order confirmation emails")
    else:
        print("\n❌ Please fix the issues above and try again.")


if __name__ == '__main__':
    main()

# Made with Bob
