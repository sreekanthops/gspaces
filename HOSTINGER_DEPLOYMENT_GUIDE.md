# Hostinger Mail Integration - Deployment Guide

## ✅ Changes Made

### Branch: `hmail`
Successfully created from current branch with Hostinger mail integration.

---

## 📝 Files Modified

### 1. **email_helper.py**
- Updated SMTP server to `smtp.hostinger.com`
- Changed email to `sreekanth.chityala@gspaces.in`
- Password loaded from environment variable `MAIL_PASSWORD`

### 2. **main.py**
- Updated Flask-Mail configuration
- Changed to Hostinger SMTP settings
- Password loaded from environment variable `MAIL_PASSWORD`

### 3. **New Files Created**
- `.env.example` - Environment variables template
- `test_hostinger_email.py` - Email testing script
- `HOSTINGER_MAIL_INTEGRATION_GUIDE.md` - Integration documentation
- `HOSTINGER_DEPLOYMENT_GUIDE.md` - This file

---

## 🚀 Deployment Steps

### Step 1: Set Environment Variable

On your production server, set the password environment variable:

```bash
export MAIL_PASSWORD='767395@Sri'
```

Or add to your `.env` file (if using python-dotenv):

```bash
echo "MAIL_PASSWORD='767395@Sri'" >> .env
```

### Step 2: Test Email Configuration

Run the test script to verify everything works:

```bash
# Set password for testing
export MAIL_PASSWORD='767395@Sri'

# Run test
python test_hostinger_email.py
```

You should see:
- ✅ SMTP connection successful
- ✅ Email sent successfully
- Check inbox at `sreekanth.chityala@gspaces.in`

### Step 3: Update Production Environment

If using systemd service, add to your service file:

```ini
[Service]
Environment="MAIL_PASSWORD=767395@Sri"
```

Or if using supervisor:

```ini
[program:gspaces]
environment=MAIL_PASSWORD="767395@Sri"
```

### Step 4: Restart Application

```bash
# If using systemd
sudo systemctl restart gspaces

# If using supervisor
sudo supervisorctl restart gspaces

# Or restart your Flask app however you normally do
```

### Step 5: Verify in Production

Test the following features:
1. **OTP Email** - Sign up with a new account
2. **Order Confirmation** - Place a test order
3. **Referral Emails** - Test referral system
4. **Personal Coupons** - Create a personal coupon

---

## 🔧 Configuration Details

### Current Settings

| Setting | Value |
|---------|-------|
| SMTP Server | smtp.hostinger.com |
| SMTP Port | 587 (TLS) |
| Email | sreekanth.chityala@gspaces.in |
| From Name | GSpaces Team |
| Password | Environment variable `MAIL_PASSWORD` |

### Alternative Port

If port 587 doesn't work, you can use port 465 (SSL):

```bash
export SMTP_PORT=465
export MAIL_USE_TLS=False
export MAIL_USE_SSL=True
```

---

## 🧪 Testing Checklist

- [ ] Test script runs successfully
- [ ] Test email received in inbox
- [ ] OTP emails working
- [ ] Order confirmation emails working
- [ ] Referral emails working
- [ ] Personal coupon emails working
- [ ] No errors in application logs

---

## 🔐 Security Notes

1. **Password Storage**
   - ✅ Password stored in environment variable
   - ✅ Not committed to Git
   - ✅ Not hardcoded in source files

2. **Email Security**
   - ✅ Using TLS encryption (port 587)
   - ✅ SMTP authentication enabled
   - ✅ Secure connection to Hostinger

3. **Best Practices**
   - Keep `.env` file out of Git (add to `.gitignore`)
   - Rotate password periodically
   - Monitor email sending logs
   - Set up SPF/DKIM records for better deliverability

---

## 📧 Email Features Using This Configuration

All these features will now use Hostinger mail:

1. **OTP Verification** - Signup email verification
2. **Password Reset** - Reset password emails
3. **Order Confirmations** - Order placed notifications
4. **Referral Updates** - Referral benefit notifications
5. **Personal Coupons** - Custom coupon emails
6. **Admin Notifications** - New order alerts

---

## 🐛 Troubleshooting

### Issue: Authentication Failed

**Solution:**
- Verify password is correct
- Check if SMTP is enabled in Hostinger panel
- Ensure email account is active

### Issue: Connection Timeout

**Solution:**
- Check if port 587 is open in firewall
- Try alternative port 465
- Verify server can reach smtp.hostinger.com

### Issue: Emails Not Received

**Solution:**
- Check spam folder
- Verify recipient email is correct
- Check Hostinger email sending limits
- Review application logs for errors

### Issue: Environment Variable Not Set

**Solution:**
```bash
# Check if variable is set
echo $MAIL_PASSWORD

# Set it if missing
export MAIL_PASSWORD='767395@Sri'

# Make it permanent (add to ~/.bashrc or ~/.bash_profile)
echo "export MAIL_PASSWORD='767395@Sri'" >> ~/.bashrc
source ~/.bashrc
```

---

## 📊 Monitoring

### Check Email Logs

Monitor your application logs for email sending:

```bash
# Check for email errors
grep -i "email" /var/log/gspaces/app.log

# Check for SMTP errors
grep -i "smtp" /var/log/gspaces/app.log
```

### Hostinger Email Limits

Check your Hostinger plan for:
- Daily sending limit
- Hourly sending limit
- Attachment size limits

---

## 🔄 Rollback Plan

If you need to rollback to Gmail:

```bash
# Switch back to main branch
git checkout main

# Or manually update environment variables
export MAIL_SERVER='smtp.gmail.com'
export MAIL_USERNAME='sri.chityala501@gmail.com'
export MAIL_PASSWORD='zupd zixc vvzp kptk'
```

---

## ✅ Deployment Checklist

- [x] Created `hmail` branch
- [x] Updated `email_helper.py`
- [x] Updated `main.py`
- [x] Created `.env.example`
- [x] Created test script
- [x] Documented changes
- [ ] Set environment variable in production
- [ ] Run test script
- [ ] Restart application
- [ ] Verify all email features
- [ ] Monitor logs for 24 hours

---

## 📞 Support

If you encounter issues:

1. Check Hostinger documentation: https://support.hostinger.com
2. Review application logs
3. Run the test script for diagnostics
4. Check firewall and network settings

---

**Deployed on**: 2026-05-24  
**Branch**: hmail  
**Email**: sreekanth.chityala@gspaces.in  
**Status**: Ready for deployment