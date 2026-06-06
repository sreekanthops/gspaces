-- Create sale_products table for PostgreSQL
CREATE TABLE IF NOT EXISTS sale_products (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2) NOT NULL,
    discount_percentage INTEGER,
    sale_start_time TIMESTAMP NOT NULL,
    sale_end_time TIMESTAMP NOT NULL,
    contact_phone VARCHAR(20) DEFAULT '+919876543210',
    contact_whatsapp VARCHAR(20) DEFAULT '+919876543210',
    show_contact BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sale_active ON sale_products(is_active, sale_end_time);
CREATE INDEX IF NOT EXISTS idx_sale_times ON sale_products(sale_start_time, sale_end_time);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_sale_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sale_products_updated_at_trigger
BEFORE UPDATE ON sale_products
FOR EACH ROW
EXECUTE FUNCTION update_sale_products_updated_at();

-- Made with Bob
