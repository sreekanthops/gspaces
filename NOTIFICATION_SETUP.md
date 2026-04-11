# GSpaces Notification System Setup Guide

## Overview

The GSpaces notification system sends automated notifications for:
- **New Orders**: Admin receives notification when a customer places an order
- **Order Status Updates**: Customer receives notification when order status changes

Notifications can be sent via:
- **Email** (Free using Gmail SMTP)
- **WhatsApp** (Free using CallMeBot API)

---

## Email Notifications Setup

### Option 1: Gmail (Recommended for Testing)

1. **Enable 2-Factor Authentication** on your Gmail account
   - Go to: https://myaccount.google.com/security
   - Enable 2-Step Verification

2. **Generate App Password**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Name it "GSpaces Notifications"
   - Copy the 16-character password

3. **Set Environment Variables**
   ```bash
   export SMTP_SERVER="smtp.gmail.com"
   export SMTP_PORT="587"
   export SMTP_USERNAME="your-email@gmail.com"
   export SMTP_PASSWORD="your-16-char-app-password"
   export SMTP_FROM_EMAIL="your-email@gmail.com"
   export ADMIN_EMAIL="admin@gspaces.com"
   export ENABLE_EMAIL_NOTIFICATIONS="true"
   ```

### Option 2: Other SMTP Providers

**SendGrid (Free tier: 100 emails/day)**
```bash
export SMTP_SERVER="smtp.sendgrid.net"
export SMTP_PORT="587"
export SMTP_USERNAME="apikey"
export SMTP_PASSWORD="your-sendgrid-api-key"
```

**Mailgun (Free tier: 5,000 emails/month)**
```bash
export SMTP_SERVER="smtp.mailgun.org"
export SMTP_PORT="587"
export SMTP_USERNAME="postmaster@your-domain.mailgun.org"
export SMTP_PASSWORD="your-mailgun-password"
```

---

## WhatsApp Notifications Setup

### Using CallMeBot (100% Free)

CallMeBot is a free service that allows sending WhatsApp messages via API.

#### Step 1: Get Your API Key

1. **Add CallMeBot to your contacts**
   - Save this number: **+34 644 44 71 67**
   - Save contact name as: **CallMeBot**

2. **Send activation message**
   - Open WhatsApp
   - Send this exact message to CallMeBot: `I allow callmebot to send me messages`
   - You'll receive your API key in response (format: `123456`)

3. **Set Environment Variables**
   ```bash
   export WHATSAPP_API_KEY="your-api-key-from-callmebot"
   export ADMIN_PHONE="+917075077384"  # Your WhatsApp number with country code
   export ENABLE_WHATSAPP_NOTIFICATIONS="true"
   ```

#### Important Notes:
- Phone number must include country code (e.g., +91 for India)
- No spaces or special characters in phone number
- API key is specific to your phone number
- Free service with no message limits
- Messages appear from CallMeBot number

### Alternative: Twilio WhatsApp (Requires Account)

If you prefer Twilio (more professional but requires account):

1. Sign up at: https://www.twilio.com/try-twilio
2. Get free trial credits ($15)
3. Set up WhatsApp sandbox
4. Update `notifications.py` to use Twilio API

---

## Environment Variables Reference

### Required for Email Notifications
```bash
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
ADMIN_EMAIL=admin@gspaces.com
ENABLE_EMAIL_NOTIFICATIONS=true
```

### Required for WhatsApp Notifications
```bash
WHATSAPP_API_KEY=your-callmebot-api-key
ADMIN_PHONE=+919876543210
ENABLE_WHATSAPP_NOTIFICATIONS=true
```

---

## Setting Environment Variables

### Development (Local)

**Linux/Mac:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export SMTP_USERNAME="your-email@gmail.com"
export SMTP_PASSWORD="your-app-password"
export ADMIN_EMAIL="admin@gspaces.com"
export ADMIN_PHONE="+919876543210"
export WHATSAPP_API_KEY="123456"
export ENABLE_EMAIL_NOTIFICATIONS="true"
export ENABLE_WHATSAPP_NOTIFICATIONS="true"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

**Windows:**
```cmd
setx SMTP_USERNAME "your-email@gmail.com"
setx SMTP_PASSWORD "your-app-password"
setx ADMIN_EMAIL "admin@gspaces.com"
setx ADMIN_PHONE "+919876543210"
setx WHATSAPP_API_KEY "123456"
setx ENABLE_EMAIL_NOTIFICATIONS "true"
setx ENABLE_WHATSAPP_NOTIFICATIONS "true"
```

### Production (EC2/Server)

1. **Edit systemd service file:**
   ```bash
   sudo nano /etc/systemd/system/gspaces.service
   ```

2. **Add environment variables in [Service] section:**
   ```ini
   [Service]
   Environment="SMTP_USERNAME=your-email@gmail.com"
   Environment="SMTP_PASSWORD=your-app-password"
   Environment="ADMIN_EMAIL=admin@gspaces.com"
   Environment="ADMIN_PHONE=+919876543210"
   Environment="WHATSAPP_API_KEY=123456"
   Environment="ENABLE_EMAIL_NOTIFICATIONS=true"
   Environment="ENABLE_WHATSAPP_NOTIFICATIONS=true"
   ```

3. **Reload and restart:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart gspaces
   ```

---

## Testing Notifications

### Test Script

Run the test script to verify your setup:

```bash
cd ~/gspaces
python notifications.py
```

This will:
- Send a test email to ADMIN_EMAIL
- Send a test WhatsApp message to ADMIN_PHONE (if configured)
- Display success/failure for each

### Manual Testing

1. **Test Email:**
   ```python
   from notifications import send_email_notification
   
   send_email_notification(
       "your-email@gmail.com",
       "Test Email",
       "<h1>Test</h1><p>This is a test email.</p>",
       "Test\n\nThis is a test email."
   )
   ```

2. **Test WhatsApp:**
   ```python
   from notifications import send_whatsapp_notification
   
   send_whatsapp_notification(
       "+919876543210",
       "🧪 Test message from GSpaces"
   )
   ```

---

## Notification Events

### 1. New Order Notification (to Admin)

**Triggered when:** Customer completes payment

**Sent to:** ADMIN_EMAIL and ADMIN_PHONE

**Contains:**
- Order ID
- Customer name and email
- Number of items
- Total amount
- Link to view order details

### 2. Order Status Update (to Customer)

**Triggered when:** Admin updates order status

**Sent to:** Customer's email and phone (from order)

**Contains:**
- Order ID
- New status with emoji
- Timestamp
- Link to track order

**Status Flow:**
- 📝 Order Placed
- ✅ Confirmed
- 📦 Packed
- 🚚 Shipped
- 🏃 Out for Delivery
- 🎉 Delivered

---

## Troubleshooting

### Email Issues

**Problem:** "Authentication failed"
- **Solution:** Make sure you're using App Password, not regular Gmail password
- Enable 2FA first, then generate App Password

**Problem:** "Connection refused"
- **Solution:** Check SMTP_SERVER and SMTP_PORT are correct
- Verify firewall isn't blocking port 587

**Problem:** Emails going to spam
- **Solution:** 
  - Use a verified domain email
  - Add SPF/DKIM records to your domain
  - Ask recipients to whitelist your email

### WhatsApp Issues

**Problem:** "API key not configured"
- **Solution:** Make sure you've sent the activation message to CallMeBot
- Check WHATSAPP_API_KEY environment variable is set

**Problem:** Messages not received
- **Solution:**
  - Verify phone number format (+countrycode without spaces)
  - Check you've saved CallMeBot contact
  - Wait a few minutes (service can be slow sometimes)

**Problem:** "Invalid phone number"
- **Solution:** 
  - Must include country code with +
  - Remove any spaces, dashes, or parentheses
  - Example: +919876543210 (not 9876543210 or +91 98765 43210)

### General Issues

**Problem:** Notifications not sending
- **Solution:** 
  - Check environment variables are set: `echo $SMTP_USERNAME`
  - Verify ENABLE_EMAIL_NOTIFICATIONS="true"
  - Check application logs for errors
  - Run test script to isolate issue

**Problem:** Only some notifications work
- **Solution:**
  - Email and WhatsApp are independent
  - Check each service's environment variables separately
  - You can enable one and disable the other

---

## Security Best Practices

1. **Never commit credentials to Git**
   - Use environment variables only
   - Add `.env` to `.gitignore` if using dotenv

2. **Use App Passwords**
   - Never use your main Gmail password
   - Generate separate app passwords for each application

3. **Rotate credentials regularly**
   - Change SMTP passwords every 3-6 months
   - Regenerate API keys periodically

4. **Limit access**
   - Only set ADMIN_EMAIL and ADMIN_PHONE for authorized personnel
   - Don't share API keys

5. **Monitor usage**
   - Check email sending limits
   - Monitor for unusual activity

---

## Cost Analysis

### Email Notifications

| Provider | Free Tier | Cost After |
|----------|-----------|------------|
| Gmail | Unlimited (with limits) | Free |
| SendGrid | 100/day | $14.95/month |
| Mailgun | 5,000/month | $35/month |
| AWS SES | 62,000/month | $0.10/1000 |

### WhatsApp Notifications

| Provider | Free Tier | Cost After |
|----------|-----------|------------|
| CallMeBot | Unlimited | Free forever |
| Twilio | $15 credit | $0.005/message |
| WhatsApp Business API | None | $0.005-0.09/message |

**Recommendation:** Use Gmail + CallMeBot for completely free notifications!

---

## Advanced Configuration

### Custom Email Templates

Edit `notifications.py` to customize email templates:
- Modify HTML in `notify_new_order()` function
- Change colors, fonts, layout
- Add company logo

### Custom WhatsApp Messages

Edit `notifications.py` to customize WhatsApp messages:
- Modify message format in `notify_order_status_update()`
- Add emojis, formatting
- Include additional information

### Disable Specific Notifications

```bash
# Disable email, keep WhatsApp
export ENABLE_EMAIL_NOTIFICATIONS="false"
export ENABLE_WHATSAPP_NOTIFICATIONS="true"

# Disable WhatsApp, keep email
export ENABLE_EMAIL_NOTIFICATIONS="true"
export ENABLE_WHATSAPP_NOTIFICATIONS="false"

# Disable all notifications
export ENABLE_EMAIL_NOTIFICATIONS="false"
export ENABLE_WHATSAPP_NOTIFICATIONS="false"
```

---

## Support

For issues or questions:
- Check logs: `sudo journalctl -u gspaces -f`
- Run test script: `python notifications.py`
- Review this documentation
- Check environment variables: `printenv | grep SMTP`

---

## Quick Start Checklist

- [ ] Set up Gmail App Password
- [ ] Configure SMTP environment variables
- [ ] Set ADMIN_EMAIL
- [ ] Get CallMeBot API key (send activation message)
- [ ] Configure WhatsApp environment variables
- [ ] Set ADMIN_PHONE
- [ ] Run test script: `python notifications.py`
- [ ] Place test order to verify
- [ ] Update order status to verify customer notification

---

**Last Updated:** April 2026
**Version:** 1.0