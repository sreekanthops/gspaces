# generate_sitemap.py

from main import app, connect_to_db
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

def build_sitemap():
    """Generate comprehensive sitemap with static pages and dynamic product pages"""
    
    # Build XML structure
    urlset = ET.Element("urlset", {
        "xmlns": "http://www.sitemaps.org/schemas/sitemap/0.9",
        "xmlns:image": "http://www.google.com/schemas/sitemap-image/1.1"
    })
    
    today = datetime.now(timezone.utc).date().isoformat()
    
    # Define static pages with priorities
    static_pages = [
        {"path": "/", "priority": "1.0", "changefreq": "daily"},
        {"path": "/about", "priority": "0.8", "changefreq": "monthly"},
        {"path": "/services", "priority": "0.8", "changefreq": "monthly"},
        {"path": "/contact", "priority": "0.7", "changefreq": "monthly"},
        {"path": "/privacy", "priority": "0.5", "changefreq": "yearly"},
        {"path": "/terms", "priority": "0.5", "changefreq": "yearly"},
        {"path": "/refund", "priority": "0.5", "changefreq": "yearly"},
        {"path": "/shipping", "priority": "0.5", "changefreq": "yearly"},
    ]
    
    # Add static pages
    for page in static_pages:
        url = ET.SubElement(urlset, "url")
        ET.SubElement(url, "loc").text = f"https://gspaces.in{page['path']}"
        ET.SubElement(url, "lastmod").text = today
        ET.SubElement(url, "changefreq").text = page['changefreq']
        ET.SubElement(url, "priority").text = page['priority']
    
    # Add dynamic product pages
    products = []
    conn = connect_to_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("SELECT id, name, image_url FROM products ORDER BY id")
            products = cur.fetchall()
            
            for product in products:
                product_id, product_name, image_url = product
                url = ET.SubElement(urlset, "url")
                ET.SubElement(url, "loc").text = f"https://gspaces.in/product/{product_id}"
                ET.SubElement(url, "lastmod").text = today
                ET.SubElement(url, "changefreq").text = "weekly"
                ET.SubElement(url, "priority").text = "0.9"
                
                # Add image information for better SEO
                if image_url:
                    image = ET.SubElement(url, "image:image")
                    ET.SubElement(image, "image:loc").text = f"https://gspaces.in/static/{image_url}"
                    ET.SubElement(image, "image:title").text = product_name
            
            cur.close()
            print(f"Added {len(products)} product pages to sitemap")
        except Exception as e:
            print(f"Error fetching products: {e}")
            products = []
        finally:
            conn.close()
    
    # Write to file with pretty formatting
    tree = ET.ElementTree(urlset)
    ET.indent(tree, space="  ")
    tree.write("sitemap.xml", encoding="utf-8", xml_declaration=True)
    
    total_urls = len(static_pages) + len(products)
    print(f"\n✓ Generated sitemap.xml with {total_urls} URLs")
    print(f"  • {len(static_pages)} static pages")
    if products:
        print(f"  • {len(products)} product pages")
    print(f"\nStatic pages included:")
    for page in static_pages:
        print(f"  • {page['path']} (priority: {page['priority']})")

if __name__ == "__main__":
    build_sitemap()
