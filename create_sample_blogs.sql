-- Insert sample blog posts for GSpaces
-- Make sure to replace USER_ID with an actual admin user ID from your users table

-- First, let's get or create a user for the blog posts
-- You can replace this with your actual admin user ID
DO $$
DECLARE
    blog_user_id INTEGER;
    blog1_id INTEGER;
    blog2_id INTEGER;
    blog3_id INTEGER;
BEGIN
    -- Get the first admin user or create a blog author
    SELECT id INTO blog_user_id FROM users WHERE is_admin = true LIMIT 1;
    
    -- If no admin user exists, you'll need to manually set the user_id
    IF blog_user_id IS NULL THEN
        RAISE NOTICE 'No admin user found. Please manually set user_id in the INSERT statements below.';
        blog_user_id := 1; -- Default to user ID 1, change this as needed
    END IF;

    -- Blog Post 1: Perfect Desk Setup Guide
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'How to Create the Perfect Desk Setup: A Complete Guide',
        '<h2>Introduction</h2>
<p>Creating the perfect desk setup is more than just aesthetics—it''s about building a workspace that enhances your productivity, comfort, and overall well-being. Whether you''re working from home, gaming, or pursuing creative projects, your desk setup plays a crucial role in your daily performance.</p>

<h2>1. Start with the Right Desk</h2>
<p>Your desk is the foundation of your entire setup. Consider these factors:</p>
<ul>
<li><strong>Size:</strong> Ensure you have enough space for your monitor(s), keyboard, mouse, and other essentials</li>
<li><strong>Height:</strong> Your desk should allow your elbows to rest at a 90-degree angle when typing</li>
<li><strong>Material:</strong> Choose durable materials that match your style and budget</li>
<li><strong>Cable Management:</strong> Look for desks with built-in cable management solutions</li>
</ul>

<h2>2. Invest in an Ergonomic Chair</h2>
<p>This is where you''ll spend most of your time, so don''t compromise on quality. A good ergonomic chair should have:</p>
<ul>
<li>Adjustable seat height and depth</li>
<li>Lumbar support that fits your lower back curve</li>
<li>Adjustable armrests</li>
<li>Breathable material</li>
<li>Smooth-rolling casters</li>
</ul>

<h2>3. Monitor Positioning</h2>
<p>Proper monitor placement prevents neck strain and eye fatigue:</p>
<ul>
<li>Position the top of your screen at or slightly below eye level</li>
<li>Keep monitors at arm''s length distance (about 20-30 inches)</li>
<li>Use a monitor arm for maximum flexibility</li>
<li>Consider dual monitors for increased productivity</li>
</ul>

<h2>4. Lighting Matters</h2>
<p>Good lighting reduces eye strain and creates a pleasant atmosphere:</p>
<ul>
<li>Natural light is best—position your desk near a window if possible</li>
<li>Add a desk lamp for task lighting</li>
<li>Consider bias lighting behind your monitor to reduce eye strain</li>
<li>Avoid glare on your screen</li>
</ul>

<h2>5. Essential Accessories</h2>
<p>Complete your setup with these must-haves:</p>
<ul>
<li><strong>Keyboard & Mouse:</strong> Choose ergonomic options that feel comfortable</li>
<li><strong>Desk Mat:</strong> Protects your desk and provides a smooth surface</li>
<li><strong>Cable Management:</strong> Keep cables organized with clips, sleeves, or boxes</li>
<li><strong>Storage Solutions:</strong> Drawers, shelves, or organizers for supplies</li>
<li><strong>Plants:</strong> Add life and improve air quality</li>
</ul>

<h2>6. Personalization</h2>
<p>Make your space truly yours:</p>
<ul>
<li>Add artwork or photos that inspire you</li>
<li>Choose a color scheme that promotes focus</li>
<li>Include items that bring you joy</li>
<li>Keep it minimal to reduce distractions</li>
</ul>

<h2>Conclusion</h2>
<p>The perfect desk setup is a personal journey. Start with the essentials—a good desk and chair—then gradually add elements that enhance your productivity and comfort. Remember, the best setup is one that works for YOUR needs and workflow.</p>

<p>At GSpaces, we offer a wide range of ergonomic furniture and accessories to help you build your ideal workspace. Visit our showroom or browse our catalog to get started!</p>',
        FLOOR(RANDOM() * 500 + 200),
        NOW() - INTERVAL '15 days',
        NOW() - INTERVAL '15 days'
    ) RETURNING id INTO blog1_id;

    -- Add thumbnail image for blog 1
    INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
    VALUES (blog1_id, 'image', 'img/banner.jpg', 1);

    -- Blog Post 2: Why Ergonomic Chairs
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'Why Ergonomic Chairs Are Worth the Investment',
        '<h2>The Hidden Cost of Poor Seating</h2>
<p>Many people spend 8-12 hours a day sitting at their desks, yet they often overlook the importance of a quality chair. Poor seating can lead to chronic back pain, reduced productivity, and long-term health issues that far outweigh the initial cost of an ergonomic chair.</p>

<h2>What Makes a Chair "Ergonomic"?</h2>
<p>An ergonomic chair is designed to support your body''s natural posture and reduce strain. Key features include:</p>
<ul>
<li><strong>Lumbar Support:</strong> Maintains the natural curve of your spine</li>
<li><strong>Adjustability:</strong> Customizes to your body dimensions</li>
<li><strong>Seat Depth:</strong> Allows proper leg positioning</li>
<li><strong>Armrests:</strong> Reduces shoulder and neck tension</li>
<li><strong>Breathable Material:</strong> Keeps you comfortable during long sessions</li>
</ul>

<h2>Health Benefits</h2>
<h3>1. Prevents Back Pain</h3>
<p>Proper lumbar support maintains your spine''s natural S-curve, preventing the slouching that leads to chronic back pain. Studies show that ergonomic chairs can reduce back pain by up to 50%.</p>

<h3>2. Improves Posture</h3>
<p>Good posture isn''t just about looking confident—it affects your breathing, digestion, and energy levels. An ergonomic chair encourages proper alignment naturally.</p>

<h3>3. Reduces Neck Strain</h3>
<p>Adjustable headrests and proper seat height prevent the forward head posture that causes neck pain and headaches.</p>

<h3>4. Increases Blood Circulation</h3>
<p>Proper seat depth and angle promote healthy blood flow to your legs, reducing the risk of deep vein thrombosis and varicose veins.</p>

<h2>Productivity Benefits</h2>
<p>Comfort directly impacts performance:</p>
<ul>
<li><strong>Better Focus:</strong> When you''re not distracted by discomfort, you can concentrate better</li>
<li><strong>Increased Energy:</strong> Proper posture improves breathing and oxygen flow</li>
<li><strong>Fewer Breaks:</strong> Comfort means less need to stand and stretch</li>
<li><strong>Long-term Sustainability:</strong> Prevents burnout from physical discomfort</li>
</ul>

<h2>The ROI of Ergonomic Chairs</h2>
<p>Consider this calculation:</p>
<ul>
<li>Average ergonomic chair cost: ₹15,000 - ₹40,000</li>
<li>Expected lifespan: 7-10 years</li>
<li>Daily cost: Less than ₹15 per day</li>
<li>Cost of back pain treatment: ₹50,000+ per year</li>
<li>Lost productivity from discomfort: Priceless</li>
</ul>

<h2>What to Look For</h2>
<p>When shopping for an ergonomic chair:</p>
<ol>
<li><strong>Test Before Buying:</strong> Sit in it for at least 15 minutes</li>
<li><strong>Check Adjustability:</strong> Can you customize all key features?</li>
<li><strong>Verify Lumbar Support:</strong> Does it fit your lower back curve?</li>
<li><strong>Consider Your Work Style:</strong> Do you need a headrest? Footrest?</li>
<li><strong>Read Reviews:</strong> Look for long-term user experiences</li>
</ol>

<h2>Common Myths Debunked</h2>
<h3>Myth 1: "Any chair with lumbar support is ergonomic"</h3>
<p>False. True ergonomic chairs offer comprehensive adjustability, not just one feature.</p>

<h3>Myth 2: "I''m young, I don''t need an ergonomic chair"</h3>
<p>Prevention is better than cure. Poor posture habits formed young can lead to serious issues later.</p>

<h3>Myth 3: "Expensive chairs are just marketing"</h3>
<p>Quality materials, engineering, and warranties justify the cost. A good chair is an investment in your health.</p>

<h2>Conclusion</h2>
<p>An ergonomic chair isn''t a luxury—it''s a necessity for anyone who spends significant time at a desk. The initial investment pays dividends in improved health, comfort, and productivity. Your future self will thank you.</p>

<p>Visit GSpaces to try our range of ergonomic chairs and find the perfect fit for your body and budget. Our experts can help you make an informed decision.</p>',
        FLOOR(RANDOM() * 400 + 150),
        NOW() - INTERVAL '10 days',
        NOW() - INTERVAL '10 days'
    ) RETURNING id INTO blog2_id;

    -- Add thumbnail image for blog 2
    INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
    VALUES (blog2_id, 'image', 'img/banner.jpg', 1);

    -- Blog Post 3: Headrest Comparison
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'Headrest vs No Headrest: Which Chair is Right for You?',
        '<h2>The Great Headrest Debate</h2>
<p>When shopping for an office chair, one of the most common questions is: "Do I need a headrest?" The answer isn''t one-size-fits-all. Let''s explore both options to help you make the right choice for your needs.</p>

<h2>Understanding Headrests</h2>
<p>A headrest (or head support) is designed to support your head and neck when you recline or take breaks. It''s not meant for constant use while working—that would indicate poor posture.</p>

<h3>Types of Headrests</h3>
<ul>
<li><strong>Fixed Headrests:</strong> Non-adjustable, built into the chair design</li>
<li><strong>Adjustable Headrests:</strong> Can be moved up/down and angled</li>
<li><strong>Removable Headrests:</strong> Can be attached or detached as needed</li>
</ul>

<h2>Benefits of Chairs WITH Headrests</h2>

<h3>1. Neck Support During Breaks</h3>
<p>When you recline to take a break or think, a headrest provides crucial support, preventing neck strain and allowing your muscles to relax.</p>

<h3>2. Ideal for Tall Users</h3>
<p>If you''re over 6 feet tall, a headrest ensures your entire spine is supported, preventing the awkward neck angle that occurs when your head extends above the chair back.</p>

<h3>3. Perfect for Recliners</h3>
<p>If you like to lean back while reading, watching videos, or taking calls, a headrest is essential for comfort and proper support.</p>

<h3>4. Reduces Tension Headaches</h3>
<p>By supporting your neck during rest periods, headrests can help prevent tension headaches caused by neck muscle fatigue.</p>

<h3>5. Better for Long Sessions</h3>
<p>During marathon work sessions, the ability to recline with full support can be a game-changer for maintaining energy and focus.</p>

<h2>Benefits of Chairs WITHOUT Headrests</h2>

<h3>1. Encourages Better Posture</h3>
<p>Without a headrest to lean on, you''re more likely to maintain proper upright posture while working, which is actually healthier for extended periods.</p>

<h3>2. More Affordable</h3>
<p>Chairs without headrests are typically less expensive, making them a budget-friendly option without sacrificing core ergonomic features.</p>

<h3>3. Sleeker Design</h3>
<p>Headrest-free chairs often have a cleaner, more minimalist aesthetic that some users prefer, especially in modern office settings.</p>

<h3>4. Better for Active Sitting</h3>
<p>If you tend to move around a lot while working, a headrest might feel restrictive. Headrest-free chairs offer more freedom of movement.</p>

<h3>5. Ideal for Shorter Users</h3>
<p>If you''re under 5''6", a headrest might not align properly with your head anyway, making it unnecessary.</p>

<h2>Who Should Choose a Headrest Chair?</h2>
<p>Consider a chair with a headrest if you:</p>
<ul>
<li>Are taller than 6 feet</li>
<li>Frequently recline while working</li>
<li>Take video calls or watch content at your desk</li>
<li>Experience neck tension or headaches</li>
<li>Work very long hours (10+ hours daily)</li>
<li>Have existing neck or upper back issues</li>
<li>Prefer maximum support options</li>
</ul>

<h2>Who Should Skip the Headrest?</h2>
<p>A headrest-free chair might be better if you:</p>
<ul>
<li>Are under 5''6" tall</li>
<li>Maintain upright posture while working</li>
<li>Prefer a minimalist aesthetic</li>
<li>Have a limited budget</li>
<li>Move around frequently while seated</li>
<li>Work in a space where a lower chair back is preferred</li>
<li>Don''t typically recline during work</li>
</ul>

<h2>The Compromise: Adjustable Headrests</h2>
<p>Can''t decide? Consider a chair with an adjustable or removable headrest. This gives you:</p>
<ul>
<li>Flexibility to use it when needed</li>
<li>Option to remove it for a cleaner look</li>
<li>Ability to adjust height and angle for perfect fit</li>
<li>Best of both worlds</li>
</ul>

<h2>Common Mistakes to Avoid</h2>

<h3>1. Using the Headrest While Working</h3>
<p>Headrests are for breaks, not active work. Leaning back constantly indicates poor desk/monitor setup.</p>

<h3>2. Choosing Based on Looks Alone</h3>
<p>A headrest might look professional, but if it doesn''t fit your body or work style, it''s just extra cost.</p>

<h3>3. Ignoring Adjustability</h3>
<p>If you do get a headrest, make sure it''s adjustable. A fixed headrest that doesn''t align with your head is worse than no headrest.</p>

<h2>Testing Tips</h2>
<p>When trying chairs:</p>
<ol>
<li>Sit in your normal working posture—does the headrest interfere?</li>
<li>Recline fully—does the headrest support your head comfortably?</li>
<li>Check if the headrest height works for your body</li>
<li>Consider your typical work activities</li>
<li>Think about your workspace aesthetics</li>
</ol>

<h2>Conclusion</h2>
<p>There''s no universal answer to the headrest question. It depends on your height, work style, budget, and personal preferences. The most important factors are proper lumbar support and seat adjustability—the headrest is a secondary consideration.</p>

<p>Visit GSpaces to try both styles and see which feels right for you. Our team can help you assess your needs and find the perfect chair, with or without a headrest.</p>',
        FLOOR(RANDOM() * 350 + 100),
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '5 days'
    ) RETURNING id INTO blog3_id;

    -- Add thumbnail image for blog 3
    INSERT INTO blog_media (blog_id, media_type, media_url, media_order)
    VALUES (blog3_id, 'image', 'img/banner.jpg', 1);

    -- Add some sample reactions to make blogs look active
    -- Note: You'll need actual user IDs or session IDs for this to work properly
    -- This is just a template - adjust as needed
    
    RAISE NOTICE 'Successfully created 3 sample blog posts!';
    RAISE NOTICE 'Blog IDs: %, %, %', blog1_id, blog2_id, blog3_id;
END $$;

-- Made with Bob
