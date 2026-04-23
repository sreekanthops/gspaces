# Instructions to Update main.py

## Step 1: Add Imports at the Top

Add these imports after your existing imports:

```python
from category_routes import register_category_routes
from category_helper import inject_categories
```

## Step 2: Register Context Processor

Add this AFTER creating the Flask app (`app = Flask(__name__)`):

```python
# Make categories available to all templates
@app.context_processor
def inject_categories_to_templates():
    return inject_categories()
```

## Step 3: Register Category Routes

Add this AFTER all your existing routes (near the end of the file, before `if __name__ == '__main__':`):

```python
# Register category management routes
register_category_routes(app)
```

## Complete Example:

```python
from flask import Flask, render_template, request, redirect, url_for, session, flash
# ... your other imports ...
from category_routes import register_category_routes
from category_helper import inject_categories

app = Flask(__name__)
app.secret_key = 'your-secret-key'

# Make categories available to all templates
@app.context_processor
def inject_categories_to_templates():
    return inject_categories()

# ... all your existing routes ...

# Register category management routes
register_category_routes(app)

if __name__ == '__main__':
    app.run(debug=True)
```

## What This Does:

1. **inject_categories()** - Automatically adds `categories` variable to ALL templates
2. **register_category_routes()** - Adds admin category management routes
3. **navbar.html** - Will now show all 7 categories dynamically
4. **"More" dropdown** - Automatically appears if more than 7 categories exist

## Verification:

After updating main.py and restarting:

1. Visit your homepage - categories should appear in navbar
2. Visit `/admin/categories` - manage categories
3. Add an 8th category - "More" dropdown should appear
4. All pages will have categories in navigation

## No Other Changes Needed!

The navbar.html is already updated to use the `categories` variable.
Just update main.py as shown above and restart your application.