-- Create wallets table for GSpaces
-- This table stores user wallet balances

-- Create wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_balance CHECK (balance >= 0)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

-- Create wallet_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT,
    balance_after DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL
);

-- Create index for faster transaction lookups
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);

-- Initialize wallets for all existing users with 0 balance
INSERT INTO wallets (user_id, balance, created_at, updated_at)
SELECT id, 0.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users
WHERE id NOT IN (SELECT user_id FROM wallets)
ON CONFLICT (user_id) DO NOTHING;

-- Display summary
SELECT 
    COUNT(*) as total_wallets,
    SUM(balance) as total_balance,
    AVG(balance) as avg_balance
FROM wallets;

-- Show sample wallets
SELECT 
    w.id,
    u.name,
    u.email,
    w.balance,
    w.created_at
FROM wallets w
JOIN users u ON w.user_id = u.id
ORDER BY w.created_at DESC
LIMIT 10;

COMMIT;

-- Made with Bob
