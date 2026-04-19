-- Upgrade reviews system to support image and video uploads
-- This script adds the review_media table for storing review images and videos

-- Create review_media table
CREATE TABLE IF NOT EXISTS review_media (
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES product_reviews(id) ON DELETE CASCADE,
    media_url VARCHAR(500) NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('image', 'video')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, media_url)
);

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_review_media_review_id ON review_media(review_id);

-- Add comment
COMMENT ON TABLE review_media IS 'Stores images and videos uploaded with product reviews';
COMMENT ON COLUMN review_media.media_type IS 'Type of media: image or video';
COMMENT ON COLUMN review_media.media_url IS 'Relative URL path to the media file';

-- Made with Bob
