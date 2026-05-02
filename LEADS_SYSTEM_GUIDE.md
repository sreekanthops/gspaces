# Leads/Quotation Management System - Complete Guide

## Overview
A comprehensive quotation management system where admins can create detailed workspace setup quotations for customers with:
- Multiple design options per lead
- Configurable pricing for all components
- Image uploads for reference and designs
- Shareable quotation URLs
- PDF export functionality
- Custom fields support

## System Architecture

### Database Tables
1. **leads** - Main customer/project information
2. **lead_designs** - Multiple design options per lead
3. **design_items** - Detailed configuration for each design
4. **design_custom_fields** - Admin-added custom items
5. **pricing_rules** - Centralized pricing management

### Key Features

#### 1. Admin Panel - Leads Management
- **Location**: `/admin/leads`
- Create new leads with customer information
- Upload main reference image
- View all leads with status filters
- Quick actions: Edit, View, Share, Delete

#### 2. Lead Editor
- **Location**: `/admin/leads/<lead_id>/edit`
- Add multiple design options
- Upload design-specific images
- Configure items for each design:
  - Tables (Iron/Wooden legs, with/without storage)
  - Chairs (Basic, Medium, High range)
  - Plants (Mini/Big)
  - Artefacts
  - Frames (Mini/Medium/Large)
  - Lighting (Table lamp, Profile light)
  - Accessories (Multisocket, Cable organizer, etc.)
  - Custom fields

#### 3. Quotation View
- **Location**: `/quotation/<share_token>`
- Public shareable URL for customers
- Professional quotation display
- PDF download option
- Shows all designs with pricing breakdown

### Pricing Logic

#### Tables
- Iron legs 4x2: ₹12,000
- Iron legs 5x2: ₹18,000
- Wooden legs U-shaped 4x2: ₹15,000
- Storage addon: +₹8,000

#### Chairs
- Basic: ₹6,000
- Basic with headrest: ₹8,000
- Medium range: ₹10,000-₹20,000 (avg ₹15,000)
- High range: ₹20,000+ (avg ₹25,000)

#### Plants
- Mini plant with pot: ₹400 each
- Big plant with pot: ₹1,000 each

#### Artefacts
- Mini artefacts: ₹700 each

#### Frames
- Mini: ₹800 each
- Medium: ₹1,200 each
- Large: ₹2,000 each

#### Lighting
- Table lamp basic: ₹1,000
- Table lamp medium: ₹2,000
- Table lamp high: ₹3,000
- Profile light: ₹300 per ft

#### Accessories
- Multisocket: ₹1,200
- Cable organiser: ₹1,200
- Desk mat: ₹1,000
- Floor mat: ₹500 per sq ft
- Clock: ₹1,000
- Pegboard: ₹1,000 per sq ft

### Discount System
- **Percentage discount**: Apply % off on total
- **Fixed amount**: Deduct fixed amount from total
- Discount shown separately in quotation

### Workflow

1. **Admin creates lead**
   - Enter customer details
   - Upload reference image
   - Save as draft

2. **Admin adds designs**
   - Create multiple design options
   - Upload design-specific images
   - Configure items for each design

3. **Admin configures items**
   - Check/uncheck items to include
   - Set quantities and specifications
   - Add custom fields if needed
   - System auto-calculates prices

4. **Apply global settings** (Optional)
   - Copy configuration to all designs
   - Individual designs can be edited later

5. **Apply discount** (Optional)
   - Set percentage or fixed discount
   - Applies to final total

6. **Share with customer**
   - Generate shareable URL
   - Customer views professional quotation
   - Customer can download PDF

7. **Track status**
   - Draft → Sent → Approved/Rejected
   - Admin can update anytime

## File Structure

```
/admin/leads                    - Leads list page
/admin/leads/create             - Create new lead
/admin/leads/<id>/edit          - Edit lead and designs
/admin/leads/<id>/delete        - Delete lead
/admin/leads/<id>/design/add    - Add new design
/admin/leads/<id>/design/<design_id>/delete - Delete design
/quotation/<share_token>        - Public quotation view
/quotation/<share_token>/pdf    - Download PDF
```

## Image Upload Locations
- Reference images: `static/img/leads/reference/`
- Design images: `static/img/leads/designs/`

## Database Schema Highlights

### Leads Table
- Customer information
- Reference image
- Status tracking
- Discount configuration
- Unique share token

### Lead Designs Table
- Multiple designs per lead
- Design-specific images
- Order/sequence

### Design Items Table
- All configurable items
- Boolean flags for enabled/disabled
- Quantities and specifications
- Auto-calculated prices
- Subtotal per design

### Custom Fields Table
- Admin-defined fields
- Flexible pricing
- Per-design customization

### Pricing Rules Table
- Centralized price management
- Admin can update prices
- Supports per-unit pricing

## Admin Features

### Bulk Operations
- Apply configuration to all designs
- Update pricing globally
- Batch status updates

### Customization
- Add unlimited custom fields
- Define custom pricing
- Upload multiple images

### Reporting
- View all leads
- Filter by status
- Track quotation performance

## Customer Experience

### Quotation View
- Clean, professional layout
- All designs displayed
- Itemized pricing
- Total with discount
- Download PDF option

### Shareable URL
- Unique token per lead
- No login required
- Mobile-responsive
- Print-friendly

## Technical Implementation

### Backend (Flask)
- Route handlers for all operations
- Image upload handling
- Price calculation logic
- PDF generation
- Database operations

### Frontend
- Bootstrap 5 for UI
- JavaScript for dynamic calculations
- AJAX for smooth interactions
- Responsive design

### PDF Generation
- WeasyPrint or ReportLab
- Professional formatting
- Company branding
- Itemized breakdown

## Deployment Steps

1. Run SQL schema: `psql -U postgres -d gspaces -f create_leads_system.sql`
2. Create upload directories
3. Install PDF library: `pip install weasyprint`
4. Deploy code changes
5. Restart application

## Security Considerations

- Admin-only access to lead management
- Secure file uploads
- Token-based sharing (no sensitive data in URL)
- Input validation
- SQL injection prevention

## Future Enhancements

- Email quotations to customers
- Customer feedback/approval system
- Version history for quotations
- Template system for common setups
- Analytics dashboard
- Integration with order system