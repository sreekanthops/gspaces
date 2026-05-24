# Hostinger Mail Integration Guide

## 📧 What You Need from Hostinger Webmail

To integrate Hostinger mail with your GSpaces application, you need to collect the following information from your Hostinger account:

### 1. **SMTP Server Details**
- **SMTP Server Address**: Usually `smtp.hostinger.com` or your domain-specific SMTP server
- **SMTP Port**: Typically `587` (TLS) or `465` (SSL)
- **Encryption Method**: TLS or SSL

### 2. **Email Account Credentials**
- **Email Address**: Your full Hostinger email address (e.g., `info@gspaces.in` or `noreply@gspaces.in`)
- **Email Password**: The password for this email account

### 3. **Additional Settings**
- **Authentication Required**: Yes (SMTP authentication)
- **From Email**: The email address that will appear as sender
- **From Name**: Display name (e.g., "GSpaces Team")

---

## 🔍 How to Get These Details from Hostinger

### Step 1: Log into Hostinger
1. Go to https://hpanel.hostinger.com
2. Log in with your Hostinger credentials

### Step 2: Access Email Settings
1. Navigate to **Emails** section in the left sidebar
2. Click on **Email Accounts**
3. Find or create the email account you want to use (e.g., `info@gspaces.in`)

### Step 3: Get SMTP Configuration
1. Click on **Manage** next to your email account
2. Look for **Email Client Configuration** or **Manual Configuration**
3. Find the **Outgoing Mail (SMTP)** settings:
   - **Server**: Usually `smtp.hostinger.com` or `smtp.yourdomain.com`
   - **Port**: `587` (recommended) or `465`
   - **Security**: STARTTLS (for port 587) or SSL/TLS (for port 465)
   - **Authentication**: Required
   - **Username**: Your full email address
   - **Password**: Your email password

### Alternative: Check Hostinger Documentation
- Go to: https://support.hostinger.com/en/articles/1583288-how-to-set-up-an-email-client
- Look for "Manual Configuration" section
- Note down the SMTP settings

---

## 📝 Information Checklist

Please provide the following details:

```
SMTP Server: _____________________________ (e.g., smtp.hostinger.com)
SMTP Port: _______________________________ (e.g., 587 or 465)
Use TLS: _________________________________ (Yes/No - typically Yes for port 587)
Email Address: ___________________________ (e.g., info@gspaces.in)
Email Password: __________________________ (Your email password)
From Name: _______________________________ (e.g., GSpaces Team)
```

---

## 🔧 Current Configuration (Gmail)

Your application currently uses:
- **SMTP Server**: `smtp.gmail.com`
- **SMTP Port**: `587`
- **Email**: `sri.chityala501@gmail.com`
- **Password**: App-specific password (hidden)

These will be replaced with your Hostinger mail settings.

---

## 📂 Files That Will Be Modified

1. **email_helper.py** (Lines 13-18)
   - SMTP server configuration
   - Email credentials

2. **main.py** (Lines 176-181)
   - Flask-Mail configuration
   - SMTP settings

---

## ⚠️ Important Notes

1. **App Password vs Regular Password**:
   - Hostinger typically uses your regular email password
   - Gmail requires app-specific passwords
   - Make sure you're using the correct password type

2. **Port Selection**:
   - Port 587 with STARTTLS is recommended (more compatible)
   - Port 465 with SSL/TLS is also secure but less flexible

3. **Firewall/Security**:
   - Ensure your server can connect to Hostinger's SMTP server
   - Port 587 or 465 should be open in your firewall

4. **Testing**:
   - After configuration, test email sending
   - Check spam folders if emails don't arrive

5. **Environment Variables** (Recommended):
   - Store credentials in environment variables
   - Don't commit passwords to Git

---

## 🚀 Next Steps

Once you provide the Hostinger mail details, I will:

1. ✅ Update `email_helper.py` with new SMTP configuration
2. ✅ Update `main.py` Flask-Mail settings
3. ✅ Create environment variable template
4. ✅ Update admin email addresses if needed
5. ✅ Create a test script to verify email sending
6. ✅ Document the changes

---

## 📧 Recommended Email Setup

For professional use, consider creating these email addresses:
- `noreply@gspaces.in` - For automated emails (OTP, notifications)
- `info@gspaces.in` - For customer inquiries
- `orders@gspaces.in` - For order confirmations
- `support@gspaces.in` - For customer support

You can use any of these as your SMTP sender address.

---

## 🔐 Security Best Practices

1. Use environment variables for credentials
2. Enable 2FA on your Hostinger account
3. Use strong, unique passwords
4. Regularly rotate email passwords
5. Monitor email sending logs
6. Set up SPF, DKIM, and DMARC records for better deliverability

---

**Created on**: 2026-05-24  
**Branch**: hmail  
**Status**: Awaiting Hostinger mail configuration details