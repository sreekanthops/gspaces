# Color-Coded Comments Guide

## Overview
The admin leads page now displays comment boxes with different colors based on customer type, making it easy to identify customer priority at a glance.

## Color Coding System

### 🟢 Green - Genuine Customers
- **Background**: Light green gradient
- **Border**: Green (#28a745)
- **Meaning**: High priority, serious buyers
- **Action**: Focus on these leads first

### 🟡 Yellow/Orange - Casual Customers  
- **Background**: Light yellow gradient
- **Border**: Orange (#ffc107)
- **Meaning**: Needs follow-up, potential buyers
- **Action**: Regular follow-up required

### 🔵 Blue - No Type Set (Default)
- **Background**: Light blue gradient
- **Border**: Cyan (#17a2b8)
- **Meaning**: Not yet categorized
- **Action**: Assess and categorize

## How to Update Customer Type

### For Existing Leads:
1. Go to **Admin Leads** page: `https://gspaces.in/admin/leads`
2. Click **"Edit"** button on any lead
3. Find **"Customer Type"** dropdown (near top of form)
4. Select either:
   - **Genuine** (for serious buyers) → Green comments
   - **Casual** (for potential buyers) → Yellow comments
5. Click **"Update Lead Info"**
6. Return to leads list - comment color will update automatically

### For New Leads:
1. Click **"Create New Lead"**
2. Fill in customer details
3. Select **Customer Type** from dropdown
4. Complete the form and save
5. Comments will show correct color from the start

## Benefits

✅ **Quick Visual Identification**: See customer priority instantly  
✅ **Better Workflow**: Prioritize genuine customers  
✅ **Team Coordination**: Everyone sees the same color coding  
✅ **Consistent System**: Colors match customer type badges

## Technical Details

- Colors are applied automatically based on `customer_type` field
- No manual color selection needed
- Updates in real-time when customer type changes
- Works for both new and existing comments

## Deployment

Already deployed in branch: `enquiry-enhancements`

To deploy to production:
```bash
cd /var/www/gspaces
git fetch origin
git checkout enquiry-enhancements
git pull origin enquiry-enhancements
sudo systemctl restart gspaces