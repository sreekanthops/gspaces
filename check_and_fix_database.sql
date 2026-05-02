-- Check and Fix Database Schema for Quantity Items System
-- Run this to diagnose and fix the issue

-- Step 1: Check if lead_designs table exists
SELECT 'Checking if lead_designs table exists...' as status;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'lead_designs'
) as table_exists;

-- Step 2: Check current columns in lead_designs
SELECT 'Current columns in lead_designs table:' as status;
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'lead_designs'
ORDER BY ordinal_position;

-- Step 3: Check if desk_mat columns exist
SELECT 'Checking for desk_mat columns...' as status;
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'lead_designs' 
AND column_name LIKE '%desk%mat%';

-- Step 4: Check if quantity columns exist for original items
SELECT 'Checking for quantity columns...' as status;
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'lead_designs' 
AND column_name LIKE '%quantity%';

-- If you see NO results above, run the migration:
-- \i add_item_quantities.sql

-- Or manually add the missing columns:
-- ALTER TABLE lead_designs ADD COLUMN IF NOT EXISTS has_desk_mat BOOLEAN DEFAULT FALSE;
-- ALTER TABLE lead_designs ADD COLUMN IF NOT EXISTS desk_mat_quantity INTEGER DEFAULT 1;
-- ALTER TABLE lead_designs ADD COLUMN IF NOT EXISTS desk_mat_price DECIMAL(10,2) DEFAULT 0;
-- ALTER TABLE lead_designs ADD COLUMN IF NOT EXISTS desk_mat_details TEXT;

-- Made with Bob
