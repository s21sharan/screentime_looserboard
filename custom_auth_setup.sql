-- Custom Authentication Setup for ScreensAway
-- This replaces Supabase Auth with a simple users table

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to read their own data
CREATE POLICY "Users can view their own data" 
    ON users FOR SELECT 
    USING (true); -- For now, allow reading all users (for login check)

-- Create policy for inserting new users
CREATE POLICY "Anyone can create a user" 
    ON users FOR INSERT 
    WITH CHECK (true); -- Allow anyone to sign up

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Update screen_time_entries to reference our users table
ALTER TABLE screen_time_entries DROP CONSTRAINT IF EXISTS screen_time_entries_user_id_fkey;
ALTER TABLE screen_time_entries 
    ADD CONSTRAINT screen_time_entries_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Update groups table
ALTER TABLE groups DROP CONSTRAINT IF EXISTS groups_created_by_fkey;
ALTER TABLE groups 
    ADD CONSTRAINT groups_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

-- Update group_members table
ALTER TABLE group_members DROP CONSTRAINT IF EXISTS group_members_user_id_fkey;
ALTER TABLE group_members 
    ADD CONSTRAINT group_members_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Drop the auth trigger since we're not using Supabase Auth
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();