-- Create product ratings and reviews system

-- Table for product reviews
CREATE TABLE IF NOT EXISTS product_reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_title VARCHAR(200),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, user_id, order_id)
);

-- Table for tracking helpful votes on reviews
CREATE TABLE IF NOT EXISTS review_helpful_votes (
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES product_reviews(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, user_id)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_rating ON product_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_product_reviews_created_at ON product_reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_review_helpful_votes_review_id ON review_helpful_votes(review_id);

-- Function to update product average rating
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET rating = (
        SELECT COALESCE(ROUND(AVG(rating)::numeric, 1), 0)
        FROM product_reviews
        WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
        AND is_approved = TRUE
    )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update product rating when review is added/updated/deleted
DROP TRIGGER IF EXISTS trigger_update_product_rating ON product_reviews;
CREATE TRIGGER trigger_update_product_rating
AFTER INSERT OR UPDATE OR DELETE ON product_reviews
FOR EACH ROW
EXECUTE FUNCTION update_product_rating();

-- Add review_count column to products table if it doesn't exist
ALTER TABLE products ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

-- Function to update review count
CREATE OR REPLACE FUNCTION update_review_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET review_count = (
        SELECT COUNT(*)
        FROM product_reviews
        WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
        AND is_approved = TRUE
    )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update review count
DROP TRIGGER IF EXISTS trigger_update_review_count ON product_reviews;
CREATE TRIGGER trigger_update_review_count
AFTER INSERT OR UPDATE OR DELETE ON product_reviews
FOR EACH ROW
EXECUTE FUNCTION update_review_count();

-- Update existing products with current review counts
UPDATE products p
SET review_count = (
    SELECT COUNT(*)
    FROM product_reviews pr
    WHERE pr.product_id = p.id
    AND pr.is_approved = TRUE
);

COMMENT ON TABLE product_reviews IS 'Stores customer reviews and ratings for products';
COMMENT ON TABLE review_helpful_votes IS 'Tracks which users found reviews helpful';

-- Made with Bob
