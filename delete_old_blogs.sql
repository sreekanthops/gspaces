-- Delete old blog posts that were created with images
-- This will remove the previous 3 blogs and their associated media

DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete blogs created in the last 30 days with media attachments
    -- This targets the blogs we created earlier with images
    DELETE FROM customer_blogs 
    WHERE id IN (
        SELECT DISTINCT cb.id 
        FROM customer_blogs cb
        INNER JOIN blog_media bm ON cb.id = bm.blog_id
        WHERE cb.created_at > NOW() - INTERVAL '30 days'
        AND cb.title IN (
            'How to Create the Perfect Desk Setup: A Complete Guide',
            'Why Ergonomic Chairs Are Worth the Investment',
            'Headrest vs No Headrest: Which Chair is Right for You?'
        )
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Deleted % old blog posts with images', deleted_count;
    
    -- Note: blog_media records will be automatically deleted due to CASCADE
END $$;

-- Made with Bob
