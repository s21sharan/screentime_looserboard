-- Group Invites Setup for ScreensAway
-- Run this after the custom_auth_setup.sql

-- Create group_invites table
CREATE TABLE IF NOT EXISTS group_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE NOT NULL,
    inviter_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    invitee_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, invitee_id)
);

-- Enable RLS
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;

-- Policies for group_invites
-- Users can see their own invites (as inviter or invitee)
CREATE POLICY "Users can view their invites" 
    ON group_invites FOR SELECT 
    USING (inviter_id = (SELECT id FROM users WHERE id = inviter_id LIMIT 1) 
        OR invitee_id = (SELECT id FROM users WHERE id = invitee_id LIMIT 1));

-- Group creators can send invites
CREATE POLICY "Group creators can send invites" 
    ON group_invites FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM groups 
            WHERE groups.id = group_id 
            AND groups.created_by = inviter_id
        )
    );

-- Invitees can update their own invites (accept/decline)
CREATE POLICY "Invitees can update their invites" 
    ON group_invites FOR UPDATE 
    USING (invitee_id = (SELECT id FROM users WHERE id = invitee_id LIMIT 1));

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_group_invites_invitee 
    ON group_invites(invitee_id, status);

CREATE INDEX IF NOT EXISTS idx_group_invites_group 
    ON group_invites(group_id, status);

-- Function to accept an invite and add user to group
CREATE OR REPLACE FUNCTION accept_group_invite(invite_id UUID)
RETURNS void AS $$
DECLARE
    v_group_id UUID;
    v_invitee_id UUID;
BEGIN
    -- Get invite details
    SELECT group_id, invitee_id INTO v_group_id, v_invitee_id
    FROM group_invites
    WHERE id = invite_id AND status = 'pending';
    
    IF v_group_id IS NOT NULL THEN
        -- Update invite status
        UPDATE group_invites 
        SET status = 'accepted', updated_at = NOW()
        WHERE id = invite_id;
        
        -- Add user to group
        INSERT INTO group_members (group_id, user_id)
        VALUES (v_group_id, v_invitee_id)
        ON CONFLICT DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;