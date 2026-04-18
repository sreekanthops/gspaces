-- Fix sri501 user who has no wallet transactions
-- Add signup bonus for this user

INSERT INTO wallet_transactions (user_id, transaction_type, amount, description, created_at)
SELECT 
    id,
    'bonus',
    500.00,
    'Welcome bonus - Thank you for joining GSpaces!',
    CURRENT_TIMESTAMP
FROM users 
WHERE email = 'sri501@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM wallet_transactions 
    WHERE user_id = users.id
);

-- Update wallet balance
UPDATE wallets w
SET balance = 500.00,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = (SELECT id FROM users WHERE email = 'sri501@gmail.com');

-- Verify the fix
SELECT u.name, u.email, w.balance, COUNT(wt.id) as transaction_count
FROM users u
JOIN wallets w ON u.id = w.user_id
LEFT JOIN wallet_transactions wt ON u.id = wt.user_id
WHERE u.email = 'sri501@gmail.com'
GROUP BY u.id, u.name, u.email, w.balance;
