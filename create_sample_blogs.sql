-- Insert sample blog posts for GSpaces
-- Short, friendly blogs about workspace setup

DO $$
DECLARE
    blog_user_id INTEGER;
    blog1_id INTEGER;
    blog2_id INTEGER;
    blog3_id INTEGER;
BEGIN
    -- Get the first admin user
    SELECT id INTO blog_user_id FROM users WHERE is_admin = true LIMIT 1;
    
    -- If no admin user exists, default to user ID 1
    IF blog_user_id IS NULL THEN
        RAISE NOTICE 'No admin user found. Using user ID 1. Please update if needed.';
        blog_user_id := 1;
    END IF;

    -- Blog Post 1: Perfect Desk Setup
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'How to Create Your Perfect Desk Setup',
        '<h2>Start with the Basics</h2>
<p>Creating a great workspace doesn''t have to be complicated! Here''s what you really need:</p>

<h3>1. The Right Desk</h3>
<p>Choose a desk that fits your space and gives you enough room for your essentials. Make sure it''s at the right height - your elbows should be at 90 degrees when typing.</p>

<h3>2. A Comfortable Chair</h3>
<p>This is where you''ll spend most of your time! Look for good back support and adjustable height. Your feet should rest flat on the floor.</p>

<h3>3. Good Lighting</h3>
<p>Natural light is best, but add a desk lamp for those late-night sessions. Position it to avoid screen glare.</p>

<h3>4. Keep It Organized</h3>
<p>Use cable organizers, desk drawers, or small boxes to keep things tidy. A clean desk = a clear mind!</p>

<h3>5. Add Personal Touches</h3>
<p>A small plant, your favorite mug, or inspiring photos make your space feel like yours.</p>

<h2>Pro Tips</h2>
<ul>
<li>Position your monitor at arm''s length</li>
<li>Take breaks every hour to stretch</li>
<li>Keep frequently used items within easy reach</li>
<li>Invest in quality over quantity</li>
</ul>

<p>Remember, the perfect setup is one that works for YOU. Start simple and add what you need over time!</p>

<p><strong>Visit GSpaces to explore our range of desks, chairs, and accessories!</strong></p>',
        0,
        NOW() - INTERVAL '7 days',
        NOW() - INTERVAL '7 days'
    ) RETURNING id INTO blog1_id;

    -- Blog Post 2: Why Ergonomic Chairs Matter
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'Why We Only Recommend Ergonomic Chairs',
        '<h2>Your Health Matters</h2>
<p>At GSpaces, we only sell ergonomic chairs. Why? Because we care about your long-term health and comfort!</p>

<h3>What Makes a Chair Ergonomic?</h3>
<p>An ergonomic chair supports your body''s natural posture. Key features include:</p>
<ul>
<li><strong>Lumbar Support:</strong> Supports your lower back curve</li>
<li><strong>Adjustable Height:</strong> Fits your body perfectly</li>
<li><strong>Comfortable Seat:</strong> Right depth and cushioning</li>
<li><strong>Armrests:</strong> Reduces shoulder tension</li>
</ul>

<h3>The Real Benefits</h3>
<p><strong>Say Goodbye to Back Pain:</strong> Proper support prevents the aches that come from poor posture.</p>

<p><strong>Work Longer, Feel Better:</strong> When you''re comfortable, you can focus on what matters without constant discomfort.</p>

<p><strong>Better Posture, Better Health:</strong> Good posture improves breathing, energy, and even confidence!</p>

<h3>Is It Worth the Investment?</h3>
<p>Think about it - you spend 8+ hours a day in your chair. That''s more time than you spend in your bed! A good ergonomic chair is an investment in your health and productivity.</p>

<h3>Our Promise</h3>
<p>Every chair at GSpaces is tested for ergonomic quality. We don''t sell anything we wouldn''t use ourselves!</p>

<p><strong>Come try our chairs in person - your back will thank you!</strong></p>',
        0,
        NOW() - INTERVAL '4 days',
        NOW() - INTERVAL '4 days'
    ) RETURNING id INTO blog2_id;

    -- Blog Post 3: Headrest Decision Guide
    INSERT INTO customer_blogs (user_id, title, content, views, created_at, updated_at)
    VALUES (
        blog_user_id,
        'Headrest or No Headrest? Here''s How to Decide',
        '<h2>The Headrest Question</h2>
<p>One of the most common questions we get: "Do I need a headrest on my chair?" Let''s make it simple!</p>

<h3>Choose a Headrest If You:</h3>
<ul>
<li>Are taller than 6 feet</li>
<li>Like to recline while thinking or taking breaks</li>
<li>Take video calls at your desk</li>
<li>Experience neck tension or headaches</li>
<li>Work very long hours</li>
</ul>

<h3>Skip the Headrest If You:</h3>
<ul>
<li>Are under 5''6" (it might not align properly)</li>
<li>Prefer sitting upright while working</li>
<li>Want a more affordable option</li>
<li>Like a minimalist look</li>
<li>Move around a lot while seated</li>
</ul>

<h3>The Truth About Headrests</h3>
<p>Here''s the thing - headrests are for BREAKS, not active work. If you''re constantly leaning back while working, your desk setup might need adjustment!</p>

<h3>Best of Both Worlds</h3>
<p>Can''t decide? Look for chairs with adjustable or removable headrests. You get flexibility without commitment!</p>

<h3>What Really Matters</h3>
<p>Honestly? The headrest is a bonus feature. What''s most important is:</p>
<ul>
<li>Good lumbar support</li>
<li>Proper seat height adjustment</li>
<li>Comfortable cushioning</li>
<li>Quality build</li>
</ul>

<h3>Try Before You Buy</h3>
<p>The best way to decide? Sit in both types! What feels right for your friend might not work for you.</p>

<p><strong>Visit our GSpaces showroom to test different chair styles and find YOUR perfect fit!</strong></p>',
        0,
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '2 days'
    ) RETURNING id INTO blog3_id;

    RAISE NOTICE 'Successfully created 3 sample blog posts!';
    RAISE NOTICE 'Blog IDs: %, %, %', blog1_id, blog2_id, blog3_id;
    RAISE NOTICE 'Views start at 0 for organic growth';
END $$;

-- Made with Bob
