-- Supabase Setup for ScreensAway (Safe Version - Checks for existing objects)
-- Run these commands in your Supabase SQL editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create a profiles table to store additional user data
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Create policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" 
    ON profiles FOR SELECT 
    USING (true);

CREATE POLICY "Users can insert their own profile" 
    ON profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON profiles FOR UPDATE 
    USING (auth.uid() = id);

-- Create a function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- Check if profile already exists
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
        INSERT INTO public.profiles (id, username)
        VALUES (
            NEW.id,
            COALESCE(
                NEW.raw_user_meta_data->>'username',
                split_part(NEW.email, '@', 1)
            )
        );
    END IF;
    
    -- Create default groups for the user
    PERFORM create_default_groups_for_user(NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to automatically create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create screen_time_entries table
CREATE TABLE IF NOT EXISTS screen_time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Enable RLS on screen_time_entries
ALTER TABLE screen_time_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all screen time entries" ON screen_time_entries;
DROP POLICY IF EXISTS "Users can insert their own screen time" ON screen_time_entries;
DROP POLICY IF EXISTS "Users can update their own screen time" ON screen_time_entries;

-- Policies for screen_time_entries
CREATE POLICY "Users can view all screen time entries" 
    ON screen_time_entries FOR SELECT 
    USING (true);

CREATE POLICY "Users can insert their own screen time" 
    ON screen_time_entries FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own screen time" 
    ON screen_time_entries FOR UPDATE 
    USING (auth.uid() = user_id);

-- Create groups table
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on groups
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Groups are viewable by everyone" ON groups;
DROP POLICY IF EXISTS "Authenticated users can create groups" ON groups;

-- Policies for groups
CREATE POLICY "Groups are viewable by everyone" 
    ON groups FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated users can create groups" 
    ON groups FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

-- Create group_members table
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Enable RLS on group_members
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Group members are viewable by everyone" ON group_members;
DROP POLICY IF EXISTS "Group creators can add members" ON group_members;

-- Policies for group_members
CREATE POLICY "Group members are viewable by everyone" 
    ON group_members FOR SELECT 
    USING (true);

CREATE POLICY "Group creators can add members" 
    ON group_members FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM groups 
            WHERE groups.id = group_id 
            AND groups.created_by = auth.uid()
        )
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_screen_time_entries_user_date 
    ON screen_time_entries(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id 
    ON group_members(group_id);

CREATE INDEX IF NOT EXISTS idx_group_members_user_id 
    ON group_members(user_id);

-- Function to create default groups for a user
CREATE OR REPLACE FUNCTION create_default_groups_for_user(user_id UUID)
RETURNS void AS $$
BEGIN
    -- Check if user already has groups
    IF NOT EXISTS (SELECT 1 FROM groups WHERE created_by = user_id) THEN
        -- Create default groups
        INSERT INTO groups (name, created_by) 
        VALUES 
            ('Family', user_id),
            ('Work Team', user_id),
            ('Friends', user_id);
            
        -- Optionally, add the user to their own groups
        INSERT INTO group_members (group_id, user_id)
        SELECT id, user_id FROM groups WHERE created_by = user_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;