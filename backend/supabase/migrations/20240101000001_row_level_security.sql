-- Row Level Security Policies
-- Ensures users can only access their own family's data

-- =============================================================================
-- ENABLE RLS ON ALL TABLES
-- =============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screen_time_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.earned_time ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- HELPER FUNCTIONS FOR RLS
-- =============================================================================

-- Get user's role
CREATE OR REPLACE FUNCTION auth.user_role() RETURNS user_role AS $$
    SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is a parent in any family
CREATE OR REPLACE FUNCTION auth.is_parent() RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.family_members
        WHERE user_id = auth.uid()
        AND role IN ('parent', 'admin')
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is a child in any family
CREATE OR REPLACE FUNCTION auth.is_child() RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.family_members
        WHERE user_id = auth.uid()
        AND role = 'child'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get user's family IDs
CREATE OR REPLACE FUNCTION auth.user_family_ids() RETURNS SETOF UUID AS $$
    SELECT family_id FROM public.family_members
    WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is parent/admin in specific family
CREATE OR REPLACE FUNCTION auth.is_family_parent(family_uuid UUID) RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.family_members
        WHERE user_id = auth.uid()
        AND family_id = family_uuid
        AND role IN ('parent', 'admin')
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is member of specific family
CREATE OR REPLACE FUNCTION auth.is_family_member(family_uuid UUID) RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.family_members
        WHERE user_id = auth.uid()
        AND family_id = family_uuid
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =============================================================================
-- USER PROFILES POLICIES
-- =============================================================================

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (id = auth.uid());

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Parents can view profiles of children in their family
CREATE POLICY "Parents can view family member profiles"
    ON public.user_profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members fm1
            JOIN public.family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = auth.uid()
            AND fm1.role IN ('parent', 'admin')
            AND fm2.user_id = user_profiles.id
        )
    );

-- =============================================================================
-- FAMILIES POLICIES
-- =============================================================================

-- Anyone authenticated can create a family
CREATE POLICY "Authenticated users can create families"
    ON public.families FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Family members can view their families
CREATE POLICY "Family members can view their families"
    ON public.families FOR SELECT
    USING (id IN (SELECT auth.user_family_ids()));

-- Family admins can update their families
CREATE POLICY "Family admins can update families"
    ON public.families FOR UPDATE
    USING (auth.is_family_parent(id));

-- Family admins can delete their families
CREATE POLICY "Family admins can delete families"
    ON public.families FOR DELETE
    USING (auth.is_family_parent(id));

-- =============================================================================
-- FAMILY MEMBERS POLICIES
-- =============================================================================

-- Family members can view other members in same family
CREATE POLICY "Family members can view other members"
    ON public.family_members FOR SELECT
    USING (family_id IN (SELECT auth.user_family_ids()));

-- Parents can add members to their family (invite children)
CREATE POLICY "Parents can add family members"
    ON public.family_members FOR INSERT
    WITH CHECK (auth.is_family_parent(family_id));

-- Users can add themselves to a family (via invite code)
CREATE POLICY "Users can join family via invite"
    ON public.family_members FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Parents can remove members from their family
CREATE POLICY "Parents can remove family members"
    ON public.family_members FOR DELETE
    USING (auth.is_family_parent(family_id));

-- Users can remove themselves from a family
CREATE POLICY "Users can leave family"
    ON public.family_members FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- DEVICES POLICIES
-- =============================================================================

-- Children can register their own devices
CREATE POLICY "Children can register own devices"
    ON public.devices FOR INSERT
    WITH CHECK (child_id = auth.uid() AND auth.is_child());

-- Children can view their own devices
CREATE POLICY "Children can view own devices"
    ON public.devices FOR SELECT
    USING (child_id = auth.uid());

-- Children can update their own devices (sync time, etc.)
CREATE POLICY "Children can update own devices"
    ON public.devices FOR UPDATE
    USING (child_id = auth.uid());

-- Parents can view devices in their family
CREATE POLICY "Parents can view family devices"
    ON public.devices FOR SELECT
    USING (auth.is_family_parent(family_id));

-- Parents can update devices in their family (remote management)
CREATE POLICY "Parents can update family devices"
    ON public.devices FOR UPDATE
    USING (auth.is_family_parent(family_id));

-- Parents can delete devices in their family
CREATE POLICY "Parents can delete family devices"
    ON public.devices FOR DELETE
    USING (auth.is_family_parent(family_id));

-- =============================================================================
-- APPS POLICIES
-- =============================================================================

-- Parents can create app categorizations
CREATE POLICY "Parents can create app categorizations"
    ON public.apps FOR INSERT
    WITH CHECK (auth.is_family_parent(family_id));

-- Family members can view apps in their family
CREATE POLICY "Family members can view family apps"
    ON public.apps FOR SELECT
    USING (auth.is_family_member(family_id));

-- Parents can update app categorizations
CREATE POLICY "Parents can update app categorizations"
    ON public.apps FOR UPDATE
    USING (auth.is_family_parent(family_id));

-- Parents can delete app categorizations
CREATE POLICY "Parents can delete app categorizations"
    ON public.apps FOR DELETE
    USING (auth.is_family_parent(family_id));

-- =============================================================================
-- SCREEN TIME RULES POLICIES
-- =============================================================================

-- Parents can create rules
CREATE POLICY "Parents can create rules"
    ON public.screen_time_rules FOR INSERT
    WITH CHECK (auth.is_family_parent(family_id));

-- Family members can view rules that apply to them
CREATE POLICY "Family members can view relevant rules"
    ON public.screen_time_rules FOR SELECT
    USING (
        auth.is_family_member(family_id)
        AND (child_id IS NULL OR child_id = auth.uid() OR auth.is_family_parent(family_id))
    );

-- Parents can update rules
CREATE POLICY "Parents can update rules"
    ON public.screen_time_rules FOR UPDATE
    USING (auth.is_family_parent(family_id));

-- Parents can delete rules
CREATE POLICY "Parents can delete rules"
    ON public.screen_time_rules FOR DELETE
    USING (auth.is_family_parent(family_id));

-- =============================================================================
-- USAGE SESSIONS POLICIES
-- =============================================================================

-- Children can create their own usage sessions
CREATE POLICY "Children can create own usage sessions"
    ON public.usage_sessions FOR INSERT
    WITH CHECK (child_id = auth.uid());

-- Children can view their own usage sessions
CREATE POLICY "Children can view own usage sessions"
    ON public.usage_sessions FOR SELECT
    USING (child_id = auth.uid());

-- Children can update their own usage sessions (end time)
CREATE POLICY "Children can update own usage sessions"
    ON public.usage_sessions FOR UPDATE
    USING (child_id = auth.uid());

-- Parents can view usage sessions of children in their family
CREATE POLICY "Parents can view family usage sessions"
    ON public.usage_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members fm1
            JOIN public.family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = auth.uid()
            AND fm1.role IN ('parent', 'admin')
            AND fm2.user_id = usage_sessions.child_id
        )
    );

-- =============================================================================
-- EARNED TIME POLICIES
-- =============================================================================

-- Children can view their own earned time
CREATE POLICY "Children can view own earned time"
    ON public.earned_time FOR SELECT
    USING (child_id = auth.uid());

-- Children can update their own earned time (via app usage)
CREATE POLICY "Children can update own earned time"
    ON public.earned_time FOR UPDATE
    USING (child_id = auth.uid());

-- Children can insert their own earned time records
CREATE POLICY "Children can insert own earned time"
    ON public.earned_time FOR INSERT
    WITH CHECK (child_id = auth.uid());

-- Parents can view earned time in their family
CREATE POLICY "Parents can view family earned time"
    ON public.earned_time FOR SELECT
    USING (auth.is_family_parent(family_id));

-- Parents can update earned time (manual adjustments)
CREATE POLICY "Parents can update family earned time"
    ON public.earned_time FOR UPDATE
    USING (auth.is_family_parent(family_id));

-- =============================================================================
-- PARENT COMMANDS POLICIES
-- =============================================================================

-- Parents can create commands for their children
CREATE POLICY "Parents can create commands"
    ON public.parent_commands FOR INSERT
    WITH CHECK (
        parent_id = auth.uid()
        AND auth.is_family_parent(family_id)
    );

-- Parents can view their own commands
CREATE POLICY "Parents can view own commands"
    ON public.parent_commands FOR SELECT
    USING (parent_id = auth.uid());

-- Children can view commands directed to them
CREATE POLICY "Children can view commands for them"
    ON public.parent_commands FOR SELECT
    USING (child_id = auth.uid());

-- Children can update command status (mark as executed)
CREATE POLICY "Children can update command status"
    ON public.parent_commands FOR UPDATE
    USING (child_id = auth.uid());

-- Parents can update their own commands
CREATE POLICY "Parents can update own commands"
    ON public.parent_commands FOR UPDATE
    USING (parent_id = auth.uid());

-- =============================================================================
-- ACTIVITY LOGS POLICIES
-- =============================================================================

-- All authenticated users can create activity logs
CREATE POLICY "Users can create activity logs"
    ON public.activity_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Family members can view logs for their family
CREATE POLICY "Family members can view family logs"
    ON public.activity_logs FOR SELECT
    USING (
        family_id IN (SELECT auth.user_family_ids())
        OR user_id = auth.uid()
    );

-- Parents can view all logs in their family
CREATE POLICY "Parents can view all family logs"
    ON public.activity_logs FOR SELECT
    USING (
        family_id IN (
            SELECT fm.family_id FROM public.family_members fm
            WHERE fm.user_id = auth.uid()
            AND fm.role IN ('parent', 'admin')
        )
    );

-- =============================================================================
-- REALTIME PUBLICATIONS
-- =============================================================================

-- Enable realtime for relevant tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.screen_time_rules;
ALTER PUBLICATION supabase_realtime ADD TABLE public.usage_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.earned_time;
ALTER PUBLICATION supabase_realtime ADD TABLE public.parent_commands;
ALTER PUBLICATION supabase_realtime ADD TABLE public.devices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.apps;

COMMENT ON POLICY "Users can view own profile" ON public.user_profiles IS 'Users can read their own profile information';
COMMENT ON POLICY "Parents can view family member profiles" ON public.user_profiles IS 'Parents can view profiles of children in their family';
