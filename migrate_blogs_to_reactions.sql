-- Migration script to update blog system from likes to reactions
-- Run this on your server database

-- Step 1: Drop old blog_likes table if exists
DROP TABLE IF EXISTS blog_likes CASCADE;

-- Step 2: Create new blog_reactions table
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

-- Step 3: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_blog_reactions_blog_id ON blog_reactions(blog_id);
CREATE INDEX IF NOT EXISTS idx_blog_reactions_type ON blog_reactions(reaction_type);

-- Migration complete
SELECT 'Blog reactions table created successfully!' as status;

-- Made with Bob
