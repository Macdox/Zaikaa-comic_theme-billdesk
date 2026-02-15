-- Fix for existing database - Add missing columns to users table
-- Run this if you already have a users table but it's missing year and branch columns

-- Check if columns exist and add them if missing
DO $$ 
BEGIN
    -- Add year column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='year'
    ) THEN
        ALTER TABLE users ADD COLUMN year INTEGER;
        RAISE NOTICE 'Added year column to users table';
    ELSE
        RAISE NOTICE 'year column already exists';
    END IF;

    -- Add branch column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='branch'
    ) THEN
        ALTER TABLE users ADD COLUMN branch VARCHAR(100);
        RAISE NOTICE 'Added branch column to users table';
    ELSE
        RAISE NOTICE 'branch column already exists';
    END IF;

    -- Add role column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='role'
    ) THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'student';
        RAISE NOTICE 'Added role column to users table';
    ELSE
        RAISE NOTICE 'role column already exists';
    END IF;

    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='created_at'
    ) THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        RAISE NOTICE 'Added created_at column to users table';
    ELSE
        RAISE NOTICE 'created_at column already exists';
    END IF;
END $$;

-- Show the current structure of the users table
\d users
