-- Sync wallet balances from wallet_transactions
-- This will calculate the correct balance for each user based on their transaction history

-- Update wallet balances based on transaction history
UPDATE wallets w
SET balance = COALESCE(
    (
        SELECT SUM(
            CASE 
                WHEN wt.transaction_type IN ('signup_bonus', 'referral_bonus', 'admin_credit', 'refund') 
                THEN wt.amount
                WHEN wt.transaction_type IN ('order_payment', 'admin_debit') 
                THEN -wt.amount
                ELSE 0
            END
        )
        FROM wallet_transactions wt
        WHERE wt.user_id = w.user_id
    ), 
    0
),
updated_at = CURRENT_TIMESTAMP;

-- Show updated balances
SELECT 
    u.name,
    u.email,
    w.balance,
    COUNT(wt.id) as transaction_count
FROM wallets w
JOIN users u ON w.user_id = u.id
LEFT JOIN wallet_transactions wt ON w.user_id = wt.user_id
GROUP BY u.name, u.email, w.balance
ORDER BY w.balance DESC;

-- Show summary
SELECT 
    COUNT(*) as total_wallets,
    SUM(balance) as total_balance,
    AVG(balance) as avg_balance,
    MAX(balance) as max_balance,
    MIN(balance) as min_balance
FROM wallets;

COMMIT;

-- Made with Bob
