-- Create sale_products table
CREATE TABLE IF NOT EXISTS sale_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2) NOT NULL,
    discount_percentage INT,
    sale_start_time DATETIME NOT NULL,
    sale_end_time DATETIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_sale_active (is_active, sale_end_time),
    INDEX idx_sale_times (sale_start_time, sale_end_time)
);

-- Add contact information columns for sale products
ALTER TABLE sale_products 
ADD COLUMN contact_phone VARCHAR(20) DEFAULT '+919876543210',
ADD COLUMN contact_whatsapp VARCHAR(20) DEFAULT '+919876543210',
ADD COLUMN show_contact BOOLEAN DEFAULT TRUE;

-- Made with Bob
