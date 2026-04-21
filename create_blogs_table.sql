-- Create customer blogs table
CREATE TABLE IF NOT EXISTS customer_blogs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create blog media table (for images and videos)
CREATE TABLE IF NOT EXISTS blog_media (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER NOT NULL REFERENCES customer_blogs(id) ON DELETE CASCADE,
    media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('image', 'video')),
    media_url VARCHAR(500) NOT NULL,
    media_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create blog reactions table (replaces likes with emoji reactions)
CREATE TABLE IF NOT EXISTS blog_reactions (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER NOT NULL REFERENCES customer_blogs(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(255),
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('love', 'fire', 'happy', 'wow', 'clap', 'heart')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blog_id, user_id, reaction_type),
    UNIQUE(blog_id, session_id, reaction_type),
    CHECK ((user_id IS NOT NULL) OR (session_id IS NOT NULL))
);

-- Create blog comments table
CREATE TABLE IF NOT EXISTS blog_comments (
    id SERIAL PRIMARY KEY,
    blog_id INTEGER NOT NULL REFERENCES customer_blogs(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_blogs_user_id ON customer_blogs(user_id);
CREATE INDEX IF NOT EXISTS idx_blogs_status ON customer_blogs(status);
CREATE INDEX IF NOT EXISTS idx_blogs_created_at ON customer_blogs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blog_media_blog_id ON blog_media(blog_id);
CREATE INDEX IF NOT EXISTS idx_blog_reactions_blog_id ON blog_reactions(blog_id);
CREATE INDEX IF NOT EXISTS idx_blog_reactions_type ON blog_reactions(reaction_type);
CREATE INDEX IF NOT EXISTS idx_blog_comments_blog_id ON blog_comments(blog_id);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_blog_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_blog_timestamp
BEFORE UPDATE ON customer_blogs
FOR EACH ROW
EXECUTE FUNCTION update_blog_timestamp();

-- Made with Bob
