# Quick Start Guide - OTP Verification System

## ⚡ Quick Setup (2 Steps Only!)

### Step 1: Run SQL to Create OTP Table
The OTP table has already been created in your local database. For the server, run:

```bash
psql -U sri -d gspaces -f create_otp_table.sql
```

**That's it for database setup!** ✅

### Step 2: Restart GSpaces Application

#### Option A: If using systemd
```bash
sudo systemctl restart gspaces
```

#### Option B: If using screen
```bash
screen -r gspaces
# Press Ctrl+C to stop
python main.py
# Press Ctrl+A then D to detach
```

#### Option C: If using pm2
```bash
pm2 restart gspaces
```

#### Option D: Manual restart
```bash
# Stop current process (Ctrl+C)
python main.py
```

## ✅ That's All!

**No other configuration needed!** The system is ready to use.

## 🧪 Quick Test

1. Go to your signup page: `http://your-domain/signup`
2. Fill in the form with a valid email (not disposable)
3. You'll receive an OTP email
4. Enter the OTP on the verification page
5. Account created + ₹500 bonus!

## 📧 Email Already Configured

Your Flask-Mail is already set up in `main.py`:
- ✅ SMTP Server: smtp.gmail.com
- ✅ Port: 587
- ✅ Username: sri.chityala501@gmail.com
- ✅ Password: Already configured
- ✅ TLS: Enabled

**No email configuration changes needed!**

## 🔍 Verify It's Working

Run the test script:
```bash
python test_otp_system.py
```

You should see:
```
✅ PASS - Database Connection
✅ PASS - OTP Table
✅ PASS - Users Table
✅ PASS - Template Files
✅ PASS - Disposable Email Detection
✅ PASS - OTP Generation
```

## 🎯 What Happens Now?

### Old Signup Flow (Before):
1. User fills form → Account created immediately → Logged in

### New Signup Flow (After):
1. User fills form → OTP sent to email
2. User enters OTP → Account created → ₹500 bonus → Logged in

## 🚫 Blocked Email Domains

These disposable email domains are automatically blocked:
- tempmail.com
- guerrillamail.com
- 10minutemail.com
- mailinator.com
- And 26 more...

## ⏱️ OTP Details

- **Valid for**: 5 minutes
- **Attempts**: Maximum 3
- **Length**: 6 digits
- **Auto-cleanup**: Expired OTPs deleted automatically

## 🎁 Signup Bonus

- **Amount**: ₹500
- **When**: After successful OTP verification
- **Where**: Automatically credited to user's wallet

## 📱 Features Active

✅ Beautiful OTP verification page
✅ Email with OTP sent automatically
✅ Countdown timer (5 minutes)
✅ Resend OTP option
✅ Auto-focus OTP inputs
✅ Paste support
✅ Mobile responsive
✅ Error handling
✅ Attempt tracking

## 🔧 Troubleshooting

### OTP Email Not Received?
1. Check spam folder
2. Verify email configuration in main.py
3. Check Flask logs for errors

### Database Error?
```bash
# Verify table exists
psql -U sri -d gspaces -c "SELECT COUNT(*) FROM otp_verifications;"
```

### Still Having Issues?
Check the logs:
```bash
# If using systemd
sudo journalctl -u gspaces -f

# If running manually
# Check terminal output
```

## 📚 Full Documentation

For detailed information, see: **OTP_VERIFICATION_GUIDE.md**

---

## Summary: What You Need to Do

1. ✅ **Database**: Already created (ran create_otp_table.sql)
2. ✅ **Code**: Already updated (main.py modified)
3. ✅ **Templates**: Already created (verify_otp.html)
4. ✅ **Email**: Already configured (Flask-Mail setup)

**Just restart GSpaces and you're done!** 🎉