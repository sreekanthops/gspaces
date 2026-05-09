-- Insert sample blog posts about workspace setup
-- Make sure to run this after the blogs table exists

INSERT INTO blogs (title, content, author_id, author_name, created_at, views, featured_image) VALUES
(
  'How to Create the Perfect Desk Setup: A Complete Guide',
  '<h2>Introduction</h2>
<p>Creating the perfect desk setup is more than just buying expensive furniture. It''s about understanding your needs, optimizing your space, and investing in the right pieces that will enhance your productivity and comfort.</p>

<h3>1. Start with Ergonomics</h3>
<p>The foundation of any great desk setup is ergonomics. Your chair should support your lower back, your monitor should be at eye level, and your keyboard should allow your arms to rest at a 90-degree angle.</p>

<h3>2. Choose the Right Desk</h3>
<p>Consider these factors when selecting a desk:</p>
<ul>
  <li><strong>Size:</strong> Ensure it fits your space and accommodates all your equipment</li>
  <li><strong>Height:</strong> Adjustable height desks are ideal for alternating between sitting and standing</li>
  <li><strong>Material:</strong> Solid wood or engineered wood for durability</li>
  <li><strong>Cable Management:</strong> Built-in cable management keeps your workspace tidy</li>
</ul>

<h3>3. Lighting Matters</h3>
<p>Proper lighting reduces eye strain and improves focus. Combine natural light with a good desk lamp. LED lights with adjustable brightness are perfect for different times of the day.</p>

<h3>4. Accessories That Make a Difference</h3>
<ul>
  <li>Monitor arm for better positioning</li>
  <li>Desk mat for comfort and aesthetics</li>
  <li>Cable organizers</li>
  <li>Desk plants for a touch of nature</li>
  <li>Headphone stand</li>
</ul>

<h3>5. Personalize Your Space</h3>
<p>Add personal touches that inspire you - photos, artwork, or motivational quotes. Your workspace should reflect your personality while maintaining professionalism.</p>

<h2>Conclusion</h2>
<p>The perfect desk setup is a balance of functionality, comfort, and personal style. Take your time to build it gradually, and don''t hesitate to adjust as your needs evolve.</p>',
  1,
  'GSpaces Team',
  NOW(),
  0,
  'img/blog-perfect-setup.jpg'
),
(
  'Why Ergonomic Chairs Are Worth the Investment',
  '<h2>The Hidden Cost of Poor Seating</h2>
<p>Many people underestimate the impact of their office chair on their health and productivity. Spending 8+ hours a day in a poorly designed chair can lead to chronic back pain, poor posture, and decreased productivity.</p>

<h3>What Makes a Chair Ergonomic?</h3>
<p>An ergonomic chair isn''t just comfortable - it''s designed to support your body''s natural alignment:</p>
<ul>
  <li><strong>Lumbar Support:</strong> Supports the natural curve of your lower back</li>
  <li><strong>Adjustable Height:</strong> Allows feet to rest flat on the floor</li>
  <li><strong>Seat Depth:</strong> Provides proper thigh support without pressure</li>
  <li><strong>Armrests:</strong> Adjustable to support arms at a 90-degree angle</li>
  <li><strong>Breathable Material:</strong> Prevents heat buildup during long sessions</li>
</ul>

<h3>The Long-Term Benefits</h3>
<p><strong>1. Improved Posture:</strong> Ergonomic chairs encourage proper spinal alignment, reducing the risk of developing chronic back problems.</p>

<p><strong>2. Increased Productivity:</strong> When you''re comfortable, you can focus better on your work without constant adjustments or discomfort.</p>

<p><strong>3. Reduced Health Risks:</strong> Proper support reduces the risk of musculoskeletal disorders, which are common among office workers.</p>

<p><strong>4. Better Circulation:</strong> Proper seat design promotes healthy blood flow to your legs and feet.</p>

<h3>ROI of an Ergonomic Chair</h3>
<p>While ergonomic chairs may seem expensive (₹15,000 - ₹50,000), consider this:</p>
<ul>
  <li>Average lifespan: 7-10 years</li>
  <li>Daily use: 8+ hours</li>
  <li>Cost per day: Less than ₹20</li>
  <li>Potential savings on medical bills: Thousands</li>
</ul>

<h2>Conclusion</h2>
<p>An ergonomic chair is not a luxury - it''s an investment in your health and productivity. Your future self will thank you for making this choice today.</p>',
  1,
  'GSpaces Team',
  NOW(),
  0,
  'img/blog-ergonomic-chair.jpg'
),
(
  'Headrest vs No Headrest: Which Chair is Right for You?',
  '<h2>The Great Headrest Debate</h2>
<p>When shopping for an office chair, one of the most common questions is: "Do I need a headrest?" The answer isn''t straightforward - it depends on your work style, posture habits, and personal preferences.</p>

<h3>Chairs with Headrest: Pros and Cons</h3>
<h4>Advantages:</h4>
<ul>
  <li><strong>Neck Support:</strong> Ideal if you frequently lean back or take breaks at your desk</li>
  <li><strong>Reduces Tension:</strong> Supports your head and neck, reducing muscle strain</li>
  <li><strong>Better for Tall People:</strong> Provides additional support for taller individuals</li>
  <li><strong>Versatility:</strong> Great for both work and relaxation</li>
</ul>

<h4>Disadvantages:</h4>
<ul>
  <li><strong>Higher Cost:</strong> Typically ₹3,000-₹8,000 more expensive</li>
  <li><strong>Space:</strong> Requires more vertical space</li>
  <li><strong>May Encourage Slouching:</strong> Some users lean back too much</li>
</ul>

<h3>Chairs without Headrest: Pros and Cons</h3>
<h4>Advantages:</h4>
<ul>
  <li><strong>More Affordable:</strong> Lower price point</li>
  <li><strong>Encourages Active Sitting:</strong> Promotes better posture</li>
  <li><strong>Compact:</strong> Fits under desks more easily</li>
  <li><strong>Lighter:</strong> Easier to move around</li>
</ul>

<h4>Disadvantages:</h4>
<ul>
  <li><strong>No Neck Support:</strong> Not ideal for leaning back</li>
  <li><strong>Less Comfortable for Breaks:</strong> Not suitable for relaxing at your desk</li>
</ul>

<h3>Who Should Choose a Headrest?</h3>
<p>Consider a chair with headrest if you:</p>
<ul>
  <li>Are taller than 5''10" (178 cm)</li>
  <li>Frequently take phone calls or video meetings</li>
  <li>Like to lean back and think</li>
  <li>Experience neck pain or tension</li>
  <li>Work long hours (10+ hours/day)</li>
</ul>

<h3>Who Can Skip the Headrest?</h3>
<p>A chair without headrest works well if you:</p>
<ul>
  <li>Maintain good posture naturally</li>
  <li>Prefer active sitting</li>
  <li>Have a limited budget</li>
  <li>Work in a compact space</li>
  <li>Rarely lean back in your chair</li>
</ul>

<h2>The Verdict</h2>
<p>There''s no universal answer. Try both types if possible. Many people find that a headrest becomes essential once they experience the comfort it provides, while others prefer the simplicity and active posture of a headrest-free chair.</p>

<p><strong>Pro Tip:</strong> If you''re unsure, choose a chair with an adjustable or removable headrest for maximum flexibility.</p>',
  1,
  'GSpaces Team',
  NOW(),
  0,
  'img/blog-headrest.jpg'
);

-- Update view counts to make them look realistic
UPDATE blogs SET views = FLOOR(RANDOM() * 500 + 100) WHERE author_name = 'GSpaces Team';

-- Made with Bob
