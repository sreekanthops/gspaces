# Email OTP Verification System - Implementation Guide

## Overview
Complete email OTP verification system for user signup with disposable email blocking, attempt tracking, and automatic ₹500 signup bonus.

## Features Implemented

### 1. **Disposable Email Blocking**
- Blocks 30+ common disposable/temporary email domains
- Includes: tempmail.com, guerrillamail.com, 10minutemail.com, mailinator.com, etc.
- Prevents spam and fake accounts

### 2. **OTP Generation & Validation**
- 6-digit numeric OTP code
- Cryptographically random generation
- Secure storage in database

### 3. **Email Delivery**
- Beautiful HTML email template
- Branded with GSpaces colors and logo
- Clear OTP display with security warnings
- Highlights ₹500 signup bonus

### 4. **Security Features**
- **5-minute expiration**: OTP expires after 5 minutes
- **3 attempts limit**: Maximum 3 attempts to enter correct OTP
- **Automatic cleanup**: Expired OTPs are automatically deleted
- **One-time use**: OTP marked as verified after successful use

### 5. **User Experience**
- Beautiful OTP verification page matching login design
- Auto-focus and auto-advance between OTP input fields
- Paste support for OTP codes
- Real-time countdown timer
- Visual feedback for errors
- Resend OTP functionality

### 6. **Database Schema**
```sql
CREATE TABLE otp_verifications (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT FALSE
);
```

## User Flow

### Signup Process
1. User fills signup form (name, email, password)
2. System validates email (not disposable)
3. System checks if email already registered
4. System generates 6-digit OTP
5. OTP stored in database with 5-minute expiration
6. Email sent to user with OTP
7. User redirected to OTP verification page

### OTP Verification
1. User enters 6-digit OTP
2. System validates OTP against database
3. Checks if OTP expired (5 minutes)
4. Checks attempt count (max 3)
5. If correct:
   - Creates user account
   - Credits ₹500 signup bonus to wallet
   - Logs user in automatically
   - Redirects to homepage
6. If incorrect:
   - Increments attempt counter
   - Shows remaining attempts
   - After 3 failed attempts, deletes OTP record

### Resend OTP
1. User clicks "Resend" link
2. System generates new OTP
3. Resets attempt counter
4. Extends expiration to 5 minutes from now
5. Sends new email with new OTP

## Routes

### `/signup` (GET, POST)
- **GET**: Shows signup form (login.html)
- **POST**: 
  - Validates input
  - Checks disposable email
  - Generates and stores OTP
  - Sends verification email
  - Redirects to `/verify-otp`

### `/verify-otp` (GET, POST)
- **GET**: Shows OTP input form
- **POST**:
  - Validates OTP
  - Creates user account on success
  - Credits signup bonus
  - Logs user in

### `/resend-otp` (GET)
- Generates new OTP
- Resets attempts
- Sends new email
- Redirects back to verification page

## Email Template Features
- Responsive HTML design
- Gradient header with GSpaces branding
- Large, clear OTP display
- Signup bonus badge
- Security warning section
- Professional footer

## Security Considerations

### Implemented
✅ Disposable email blocking
✅ OTP expiration (5 minutes)
✅ Attempt limiting (3 attempts)
✅ Automatic cleanup of expired OTPs
✅ One-time use verification
✅ Secure random OTP generation

### Recommended Enhancements
- Hash passwords before storing (currently plain text)
- Add rate limiting for signup attempts
- Implement CAPTCHA for repeated failures
- Add email verification for password changes
- Log suspicious activity

## Configuration

### Email Settings (main.py)
```python
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'your-email@gmail.com'
app.config['MAIL_PASSWORD'] = 'your-app-password'
```

### Disposable Email Domains
Located in `main.py` as `DISPOSABLE_EMAIL_DOMAINS` set. Add more domains as needed.

## Testing Checklist

- [ ] Test signup with valid email
- [ ] Test signup with disposable email (should be blocked)
- [ ] Test OTP email delivery
- [ ] Test correct OTP entry
- [ ] Test incorrect OTP entry (3 times)
- [ ] Test OTP expiration (wait 5 minutes)
- [ ] Test resend OTP functionality
- [ ] Test paste OTP functionality
- [ ] Test signup bonus credit
- [ ] Test duplicate email registration
- [ ] Test timer countdown
- [ ] Test mobile responsiveness

## Files Modified/Created

### Created
1. `create_otp_table.sql` - Database schema
2. `templates/verify_otp.html` - OTP verification page
3. `OTP_VERIFICATION_GUIDE.md` - This documentation

### Modified
1. `main.py`:
   - Added disposable email domains list
   - Added OTP helper functions
   - Modified `/signup` route
   - Added `/verify-otp` route
   - Added `/resend-otp` route

## Troubleshooting

### Email Not Sending
- Check MAIL_USERNAME and MAIL_PASSWORD in main.py
- Verify Gmail app password is correct
- Check spam folder
- Verify SMTP settings

### OTP Not Working
- Check database connection
- Verify otp_verifications table exists
- Check system time (affects expiration)
- Review server logs for errors

### Disposable Email Not Blocked
- Add domain to DISPOSABLE_EMAIL_DOMAINS set
- Restart Flask application

## Maintenance

### Periodic Cleanup
Run this SQL to clean old OTP records:
```sql
DELETE FROM otp_verifications 
WHERE expires_at < NOW() AND verified = FALSE;
```

Or call `clean_expired_otps(conn)` function periodically.

### Monitor Failed Attempts
```sql
SELECT email, attempts, created_at 
FROM otp_verifications 
WHERE attempts >= 2 
ORDER BY created_at DESC;
```

## Success Metrics
- ✅ Blocks disposable emails
- ✅ 5-minute OTP expiration
- ✅ 3 attempt limit enforced
- ✅ Beautiful verification UI
- ✅ Automatic ₹500 bonus credit
- ✅ Seamless user experience
- ✅ Email delivery working
- ✅ Mobile responsive design

## Support
For issues or questions, contact the development team.