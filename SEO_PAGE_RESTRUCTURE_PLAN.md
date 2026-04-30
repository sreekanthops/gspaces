# GSpaces SEO Page Restructure Plan

## Overview
Restructure the website from a single-page application to multi-page architecture for better SEO, while maintaining all existing functionality and adding admin controls for content management.

## Current Structure
- **index.html**: Single page with sections (home, about, corporate, products, team, contact)
- **Navigation**: Scroll-based navigation to sections within index.html
- **Content**: Hardcoded in HTML templates

## New Structure

### 1. Homepage (index.html)
**Keep:**
- Hero/banner section
- Brief overview/CTA
- Featured products preview
- Testimonials
- Quick stats

**Remove:**
- Detailed about section → Move to /about
- Corporate tie-ups section → Move to /corporate
- Full products listing → Move to /products
- Team section → Move to /team
- Contact form → Move to /contact

### 2. New Separate Pages

#### A. About Page (/about)
**Content from index.html:**
- Complete desk setup solutions section
- Mission & Vision
- What makes us different
- Company story
- Stats section

**New additions:**
- Timeline/History
- Awards & Recognition
- Admin-managed image galleries

#### B. Corporate Page (/corporate)
**Content from index.html:**
- Corporate tie-ups section
- Standardized setups
- Bulk pricing
- End-to-end setup
- CTA with phone/WhatsApp

**New additions:**
- Case studies
- Client testimonials
- Partnership benefits
- Admin-managed client logos

#### C. Products/Setups Page (/products)
**Content from index.html:**
- All product listings
- Product categories
- Filters

**Keep existing:**
- Database-driven product display
- Cart functionality
- Product detail pages

#### D. Team Page (/team)
**Content from index.html:**
- Team member cards
- Roles & responsibilities

**New additions:**
- Admin panel to add/edit team members
- Upload team photos
- Social media links

#### E. Contact Page (/contact)
**Content from index.html:**
- Contact form
- Contact information
- Map (if any)

**New additions:**
- FAQ section
- Office hours
- Multiple contact methods
- Admin-managed contact details

## Database Changes

### New Table: content_sections
```sql
- id, page_name, section_name, title, subtitle, description
- image_url, image_alt, display_order, is_active
- created_at, updated_at
```

### New Table: team_members
```sql
- id, name, role, bio, image_url, email
- linkedin_url, twitter_url, display_order, is_active
- created_at, updated_at
```

## Navigation Changes

### Old Navigation (navbar.html)
```html
<a href="{{ url_for('index', section='about') }}">About</a>
<a href="{{ url_for('index', section='corporate') }}">Corporate</a>
<a href="{{ url_for('index', section='products') }}">Setups</a>
<a href="{{ url_for('index', section='team') }}">Team</a>
<a href="{{ url_for('index', section='contact') }}">Contact</a>
```

### New Navigation
```html
<a href="{{ url_for('about') }}">About</a>
<a href="{{ url_for('corporate') }}">Corporate</a>
<a href="{{ url_for('products') }}">Products</a>
<a href="{{ url_for('team') }}">Team</a>
<a href="{{ url_for('contact') }}">Contact</a>
```

## Flask Routes (main.py)

### New Routes to Add
```python
@app.route('/about')
def about():
    sections = get_content_sections('about')
    return render_template('about.html', sections=sections)

@app.route('/corporate')
def corporate():
    sections = get_content_sections('corporate')
    return render_template('corporate.html', sections=sections)

@app.route('/products')
def products():
    # Existing products logic
    return render_template('products.html', products=products)

@app.route('/team')
def team():
    team_members = get_team_members()
    return render_template('team.html', team_members=team_members)

@app.route('/contact', methods=['GET', 'POST'])
def contact():
    # Handle contact form
    return render_template('contact.html')
```

### Admin Routes to Add
```python
@app.route('/admin/content')
@login_required
def admin_content():
    # Manage content sections
    
@app.route('/admin/content/edit/<int:id>', methods=['POST'])
@login_required
def admin_edit_content(id):
    # Edit content section with image upload

@app.route('/admin/team')
@login_required
def admin_team():
    # Manage team members

@app.route('/admin/team/add', methods=['POST'])
@login_required
def admin_add_team_member():
    # Add team member with photo upload
```

## Admin Panel Features

### Content Management
- Edit page sections (title, description, images)
- Upload/replace images for each section
- Reorder sections (drag & drop)
- Enable/disable sections
- Preview changes before publishing

### Team Management
- Add/edit/delete team members
- Upload team photos
- Set display order
- Add social media links

## SEO Benefits

1. **Multiple Pages**: More pages for Google to index
2. **Targeted Keywords**: Each page optimized for specific keywords
3. **Better URL Structure**: /about, /corporate, /products instead of /#about
4. **Improved Site Architecture**: Clear hierarchy and navigation
5. **Rich Content**: More detailed content on each page
6. **Schema Markup**: Page-specific structured data

## Implementation Steps

1. ✅ Create database tables (content_sections, team_members)
2. ⏳ Create new template pages (about.html, corporate.html, team.html, contact.html)
3. ⏳ Extract content from index.html to new pages
4. ⏳ Update navbar.html with new navigation links
5. ⏳ Add Flask routes in main.py
6. ⏳ Create admin panel for content management
7. ⏳ Add image upload functionality
8. ⏳ Update sitemap.xml
9. ⏳ Test all pages and functionality
10. ⏳ Deploy to production

## Backward Compatibility

- Keep old section anchors working with redirects
- Example: /#about → /about
- Maintain all existing database functionality
- No changes to products, cart, orders, wallet systems

## Performance Considerations

- Lazy load images on all pages
- Optimize images before upload (admin panel)
- Cache content sections
- Minify CSS/JS
- Use CDN for static assets

## Timeline

- Database setup: 30 minutes
- Template creation: 2 hours
- Admin panel: 2 hours
- Testing: 1 hour
- **Total: ~5-6 hours**

## Files to Modify

1. `create_content_sections_table.sql` ✅
2. `create_team_members_table.sql` (new)
3. `templates/index.html` (simplify)
4. `templates/about.html` (new)
5. `templates/corporate.html` (new)
6. `templates/team.html` (new)
7. `templates/contact.html` (update)
8. `templates/products.html` (new or update existing)
9. `templates/navbar.html` (update navigation)
10. `templates/admin_content.html` (new)
11. `templates/admin_team.html` (new)
12. `main.py` (add routes)
13. `sitemap.xml` (update)

## Success Metrics

- All pages load correctly
- Navigation works smoothly
- Admin can upload images
- No broken links
- All existing functionality intact
- Improved Lighthouse SEO score
- Better Google indexing
