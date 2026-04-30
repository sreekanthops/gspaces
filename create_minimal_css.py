#!/usr/bin/env python3
"""
Create minimal critical CSS for above-the-fold content
This extracts only the CSS needed for initial page render
"""

critical_css = """
/* Critical CSS for GSpaces - Above the fold only */
:root {
  --default-font: "Mozilla Text", system-ui, -apple-system, Roboto;
  --heading-font: "Mozilla Text", sans-serif;
  --background-color: #ffffff;
  --default-color: #444444;
  --heading-color: #273d4e;
  --accent-color: #ff4a17;
  --contrast-color: #ffffff;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: var(--default-font);
  color: var(--default-color);
  background-color: var(--background-color);
  line-height: 1.6;
}

.home.section {
  min-height: 100vh;
  display: flex;
  align-items: center;
  position: relative;
}

.home-content {
  position: relative;
  z-index: 2;
}

.home-image img {
  width: 100%;
  height: auto;
  display: block;
}

.home-text h2 {
  font-size: 2.5rem;
  color: var(--heading-color);
  font-weight: 700;
  margin-bottom: 1rem;
}

.home-text p {
  font-size: 1.1rem;
  margin-bottom: 1rem;
}

/* Navbar critical styles */
.header {
  background: #fff;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 15px;
}

/* Hide non-critical content initially */
.about, .services, .testimonials, .portfolio {
  visibility: hidden;
}
"""

# Write to file
with open('static/css/critical.css', 'w') as f:
    f.write(critical_css)

print("✓ Created static/css/critical.css")
print("  This file contains only critical above-the-fold CSS")
print("  Size: ~1KB (vs 100KB+ for full CSS)")

# Made with Bob
