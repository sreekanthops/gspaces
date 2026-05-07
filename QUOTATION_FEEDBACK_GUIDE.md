# Quotation Feedback Feature - Implementation Guide

## Overview
This feature allows customers to provide feedback and ratings on their quotations directly from the quotation view page. Customers can rate quotations with 1-5 stars and provide written feedback or questions.

## What Was Implemented

### 1. Frontend Changes
**File: `templates/quotation_view_simple.html`**

Added a beautiful feedback section before the footer with:
- ⭐ Star rating system (1-5 stars with interactive hover effects)
- 📝 Textarea for customer feedback/questions
- 🎨 Gradient design matching the quotation page style
- ✅ Success/error message displays
- 🔄 Real-time form validation
- 📱 Fully responsive design

**Features:**
- Interactive star rating with visual feedback
- Form validation (requires at least rating or message)
- AJAX submission without page reload
- Beautiful success/error messages
- Disabled state during submission to prevent duplicates

### 2. Backend Changes
**File: `leads_simple.py`**

Added new API endpoint:
```python
@leads_bp.route('/api/submit-quotation-feedback', methods=['POST'])
def submit_quotation_feedback()
```

**Functionality:**
- Accepts lead_id, rating (0-5), and message
- Validates input data
- Updates leads table with feedback
- Returns JSON response
- Error handling with proper HTTP status codes

### 3. Database Changes
**File: `add_quotation_feedback.sql`**

Added three new columns to the `leads` table:
- `customer_rating` (INTEGER): Star rating from 1-5
- `customer_feedback` (TEXT): Customer's written feedback
- `feedback_submitted_at` (TIMESTAMP): When feedback was submitted

**Features:**
- Check constraint ensures rating is between 0-5
- Index on feedback_submitted_at for faster queries
- Column comments for documentation
- NULL values allowed (optional feedback)

## Deployment Instructions

### Step 1: Backup
```bash
# Create backup directory
mkdir -p backups_$(date +%Y%m%d_%H%M%S)

# Backup database
pg_dump -U postgres gspaces > backups_*/gspaces_backup.sql

# Backup files
cp templates/quotation_view_simple.html backups_*/
cp leads_simple.py backups_*/
```

### Step 2: Apply Database Migration
```bash
psql -U postgres -d gspaces -f add_quotation_feedback.sql
```

### Step 3: Verify Database Changes
```sql
-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'leads' 
AND column_name IN ('customer_rating', 'customer_feedback', 'feedback_submitted_at');

-- Should return 3 rows
```

### Step 4: Deploy Code Changes
The following files have been modified and need to be deployed:
- `templates/quotation_view_simple.html` - Added feedback section
- `leads_simple.py` - Added API endpoint

### Step 5: Restart Application
```bash
# Choose the appropriate command for your setup:
sudo systemctl restart gspaces
# OR
sudo supervisorctl restart gspaces
# OR
pkill -f "python.*main.py" && nohup python main.py &
```

## Testing

### 1. Test Feedback Submission
1. Open any quotation page using the share link
2. Scroll down to the feedback section (before footer)
3. Click on stars to rate (1-5)
4. Enter feedback message (optional)
5. Click "Submit Feedback" button
6. Verify success message appears

### 2. Verify Database
```sql
-- Check submitted feedback
SELECT 
    id,
    customer_name,
    customer_rating,
    customer_feedback,
    feedback_submitted_at
FROM leads
WHERE feedback_submitted_at IS NOT NULL
ORDER BY feedback_submitted_at DESC;
```

### 3. Test Edge Cases
- Submit with only rating (no message)
- Submit with only message (no rating)
- Submit with both rating and message
- Try submitting empty form (should show error)
- Test on mobile devices

## Usage

### For Customers
1. View the quotation shared with them
2. Scroll to the "Share Your Thoughts" section
3. Rate the quotation by clicking stars (optional)
4. Write feedback or questions in the text area (optional)
5. Click "Submit Feedback"
6. See confirmation message

### For Admin
View customer feedback in the database:
```sql
-- Get all feedback
SELECT 
    l.id,
    l.customer_name,
    l.customer_email,
    l.customer_phone,
    l.customer_rating,
    l.customer_feedback,
    l.feedback_submitted_at,
    l.created_at
FROM leads l
WHERE l.customer_rating IS NOT NULL 
   OR l.customer_feedback IS NOT NULL
ORDER BY l.feedback_submitted_at DESC;

-- Get average rating
SELECT 
    AVG(customer_rating) as avg_rating,
    COUNT(*) as total_ratings
FROM leads
WHERE customer_rating IS NOT NULL;
```

## Features & Benefits

### Customer Benefits
- ✅ Easy way to provide feedback on quotations
- ✅ Can ask questions directly
- ✅ Rate their experience with the quotation
- ✅ No login required
- ✅ Beautiful, intuitive interface

### Business Benefits
- 📊 Collect valuable customer feedback
- 💡 Understand customer concerns and questions
- ⭐ Track quotation quality with ratings
- 📈 Improve quotation process based on feedback
- 🤝 Better customer engagement

## UI/UX Details

### Design Elements
- **Colors**: Gradient from indigo to purple matching quotation theme
- **Icons**: Bootstrap Icons for visual appeal
- **Animations**: Smooth hover effects on stars and button
- **Responsive**: Works perfectly on mobile, tablet, and desktop
- **Accessibility**: Proper labels and ARIA attributes

### User Flow
1. Customer views quotation
2. Scrolls to feedback section
3. Interacts with star rating (visual feedback)
4. Types feedback message
5. Submits form
6. Sees success message
7. Form resets for potential future feedback

## API Endpoint Details

### Endpoint
```
POST /api/submit-quotation-feedback
```

### Request Parameters
- `lead_id` (required): ID of the lead/quotation
- `rating` (optional): Integer 0-5
- `message` (optional): Text feedback

### Response Format
```json
{
    "success": true,
    "message": "Thank you for your feedback!"
}
```

### Error Responses
```json
{
    "success": false,
    "message": "Error description"
}
```

## Troubleshooting

### Issue: Feedback not submitting
**Solution:**
1. Check browser console for JavaScript errors
2. Verify API endpoint is accessible
3. Check database connection
4. Verify leads table has feedback columns

### Issue: Database error
**Solution:**
```sql
-- Verify columns exist
\d leads

-- If missing, run migration again
\i add_quotation_feedback.sql
```

### Issue: Success message not showing
**Solution:**
1. Check JavaScript console for errors
2. Verify AJAX response is successful
3. Check if success div element exists in HTML

## Future Enhancements

Potential improvements:
- 📧 Email notification to admin when feedback is submitted
- 📊 Admin dashboard to view all feedback
- 💬 Reply functionality for admin to respond to feedback
- 📈 Analytics dashboard for feedback trends
- 🏷️ Categorize feedback (pricing, design, timeline, etc.)
- ⭐ Display average rating on quotation
- 📱 SMS notification for urgent feedback

## Files Modified

1. **templates/quotation_view_simple.html**
   - Added feedback section HTML
   - Added JavaScript for star rating
   - Added AJAX submission handler

2. **leads_simple.py**
   - Added `/api/submit-quotation-feedback` endpoint
   - Added validation logic
   - Added database update logic

3. **add_quotation_feedback.sql** (new file)
   - Database migration script
   - Adds feedback columns to leads table

4. **deploy_quotation_feedback.sh** (new file)
   - Automated deployment script
   - Includes backup and verification

5. **QUOTATION_FEEDBACK_GUIDE.md** (this file)
   - Complete documentation

## Support

For issues or questions:
1. Check this documentation
2. Review error logs
3. Test with sample data
4. Verify all files are deployed correctly

---

**Created by:** Bob  
**Date:** 2026-05-07  
**Version:** 1.0  
**Status:** Ready for Deployment ✅