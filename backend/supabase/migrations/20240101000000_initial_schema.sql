-- Screen Time Balancer - Initial Database Schema
-- This migration creates all core tables for the MVP

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User roles enum
CREATE TYPE user_role AS ENUM ('parent', 'child');

-- Family member roles enum
CREATE TYPE family_member_role AS ENUM ('admin', 'parent', 'child');

-- App categories enum
CREATE TYPE app_category AS ENUM ('educational', 'recreational', 'utility', 'uncategorized');

-- Device platforms enum
CREATE TYPE device_platform AS ENUM ('ios', 'ipados', 'android');

-- =============================================================================
-- USER PROFILES TABLE
-- Extends Supabase auth.users with additional profile information
-- =============================================================================
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    role user_role NOT NULL,
    date_of_birth DATE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);

-- =============================================================================
-- FAMILIES TABLE
-- Represents a family account (created by parent)
-- =============================================================================
CREATE TABLE public.families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generate unique 8-character invite code
CREATE INDEX idx_families_invite_code ON public.families(invite_code);
CREATE INDEX idx_families_created_by ON public.families(created_by);

-- =============================================================================
-- FAMILY MEMBERS TABLE
-- Links users to families with specific roles
-- =============================================================================
CREATE TABLE public.family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role family_member_role NOT NULL,
    nickname TEXT, -- Optional nickname for child within family
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

CREATE INDEX idx_family_members_family_id ON public.family_members(family_id);
CREATE INDEX idx_family_members_user_id ON public.family_members(user_id);

-- =============================================================================
-- DEVICES TABLE
-- Child devices registered in the system
-- =============================================================================
CREATE TABLE public.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    device_identifier TEXT NOT NULL, -- iOS device UUID
    platform device_platform NOT NULL,
    os_version TEXT,
    app_version TEXT,
    last_sync TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(device_identifier)
);

CREATE INDEX idx_devices_child_id ON public.devices(child_id);
CREATE INDEX idx_devices_family_id ON public.devices(family_id);
CREATE INDEX idx_devices_identifier ON public.devices(device_identifier);

-- =============================================================================
-- APPS TABLE
-- Catalog of apps with categorization
-- =============================================================================
CREATE TABLE public.apps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    bundle_id TEXT NOT NULL, -- iOS bundle identifier (e.g., com.apple.mobilesafari)
    app_name TEXT NOT NULL,
    category app_category NOT NULL DEFAULT 'uncategorized',
    icon_url TEXT,
    is_blocked BOOLEAN DEFAULT false,
    time_limit_minutes INTEGER, -- Optional per-app time limit
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, bundle_id)
);

CREATE INDEX idx_apps_family_id ON public.apps(family_id);
CREATE INDEX idx_apps_bundle_id ON public.apps(bundle_id);
CREATE INDEX idx_apps_category ON public.apps(category);

-- =============================================================================
-- SCREEN TIME RULES TABLE
-- Daily requirements and schedules per child or family
-- =============================================================================
CREATE TABLE public.screen_time_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    child_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL = applies to all children
    name TEXT NOT NULL,
    description TEXT,

    -- Educational time requirements
    required_educational_minutes INTEGER NOT NULL DEFAULT 30,

    -- Recreational time limits
    max_recreational_minutes INTEGER DEFAULT 120,

    -- Time windows
    start_time TIME, -- When rule starts (e.g., 06:00)
    end_time TIME,   -- When rule ends (e.g., 21:00)

    -- Days of week (JSON array: [0,1,2,3,4,5,6] where 0=Sunday)
    active_days JSONB DEFAULT '[0,1,2,3,4,5,6]',

    -- Rule priority (higher = more important)
    priority INTEGER DEFAULT 0,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_screen_time_rules_family_id ON public.screen_time_rules(family_id);
CREATE INDEX idx_screen_time_rules_child_id ON public.screen_time_rules(child_id);
CREATE INDEX idx_screen_time_rules_active ON public.screen_time_rules(is_active);

-- =============================================================================
-- USAGE SESSIONS TABLE
-- Tracks app usage on child devices
-- =============================================================================
CREATE TABLE public.usage_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    app_id UUID REFERENCES public.apps(id) ON DELETE SET NULL,
    bundle_id TEXT NOT NULL,
    app_name TEXT NOT NULL,
    category app_category NOT NULL,

    -- Session timing
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,

    -- Metadata
    date DATE NOT NULL, -- For easy daily queries
    synced_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usage_sessions_child_id ON public.usage_sessions(child_id);
CREATE INDEX idx_usage_sessions_device_id ON public.usage_sessions(device_id);
CREATE INDEX idx_usage_sessions_date ON public.usage_sessions(date);
CREATE INDEX idx_usage_sessions_category ON public.usage_sessions(category);
CREATE INDEX idx_usage_sessions_started_at ON public.usage_sessions(started_at);

-- =============================================================================
-- EARNED TIME TABLE
-- Tracks daily earned recreational time per child
-- =============================================================================
CREATE TABLE public.earned_time (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Time tracking (in minutes)
    educational_minutes INTEGER DEFAULT 0,
    required_educational_minutes INTEGER NOT NULL,
    recreational_minutes_used INTEGER DEFAULT 0,
    recreational_minutes_available INTEGER DEFAULT 0,

    -- Status
    requirement_met BOOLEAN DEFAULT false,
    last_calculated TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(child_id, date)
);

CREATE INDEX idx_earned_time_child_id ON public.earned_time(child_id);
CREATE INDEX idx_earned_time_date ON public.earned_time(date);
CREATE INDEX idx_earned_time_family_id ON public.earned_time(family_id);

-- =============================================================================
-- PARENT COMMANDS TABLE
-- Remote commands from parent to child device
-- =============================================================================
CREATE TABLE public.parent_commands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.devices(id) ON DELETE SET NULL,

    command_type TEXT NOT NULL, -- 'lock', 'unlock', 'pause', 'resume', 'update_rules'
    payload JSONB, -- Additional command data

    -- Status tracking
    status TEXT DEFAULT 'pending', -- 'pending', 'delivered', 'executed', 'failed'
    executed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour'
);

CREATE INDEX idx_parent_commands_child_id ON public.parent_commands(child_id);
CREATE INDEX idx_parent_commands_device_id ON public.parent_commands(device_id);
CREATE INDEX idx_parent_commands_status ON public.parent_commands(status);
CREATE INDEX idx_parent_commands_created_at ON public.parent_commands(created_at);

-- =============================================================================
-- ACTIVITY LOGS TABLE
-- Audit trail for important actions
-- =============================================================================
CREATE TABLE public.activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT, -- 'rule', 'app', 'device', 'family_member'
    entity_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_family_id ON public.activity_logs(family_id);
CREATE INDEX idx_activity_logs_user_id ON public.activity_logs(user_id);
CREATE INDEX idx_activity_logs_created_at ON public.activity_logs(created_at);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to generate random invite code
CREATE OR REPLACE FUNCTION generate_invite_code() RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Removed ambiguous chars
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate earned recreational time
CREATE OR REPLACE FUNCTION calculate_earned_time(
    p_child_id UUID,
    p_date DATE
) RETURNS INTEGER AS $$
DECLARE
    v_educational_minutes INTEGER;
    v_required_minutes INTEGER;
    v_earned_minutes INTEGER;
BEGIN
    -- Get total educational minutes for the date
    SELECT COALESCE(SUM(duration_seconds) / 60, 0)
    INTO v_educational_minutes
    FROM usage_sessions
    WHERE child_id = p_child_id
      AND date = p_date
      AND category = 'educational';

    -- Get required educational minutes
    SELECT required_educational_minutes
    INTO v_required_minutes
    FROM screen_time_rules
    WHERE (child_id = p_child_id OR child_id IS NULL)
      AND is_active = true
    ORDER BY priority DESC, child_id NULLS LAST
    LIMIT 1;

    -- Calculate earned time (1:1 ratio for MVP)
    IF v_educational_minutes >= v_required_minutes THEN
        v_earned_minutes := v_educational_minutes;
    ELSE
        v_earned_minutes := 0;
    END IF;

    RETURN v_earned_minutes;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Update updated_at on user_profiles
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on families
CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON public.families
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on apps
CREATE TRIGGER update_apps_updated_at
    BEFORE UPDATE ON public.apps
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on screen_time_rules
CREATE TRIGGER update_screen_time_rules_updated_at
    BEFORE UPDATE ON public.screen_time_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on earned_time
CREATE TRIGGER update_earned_time_updated_at
    BEFORE UPDATE ON public.earned_time
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate invite code on family creation
CREATE OR REPLACE FUNCTION auto_generate_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invite_code
    BEFORE INSERT ON public.families
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_invite_code();

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- View: Daily usage summary per child
CREATE OR REPLACE VIEW daily_usage_summary AS
SELECT
    us.child_id,
    us.date,
    us.device_id,
    SUM(CASE WHEN us.category = 'educational' THEN us.duration_seconds ELSE 0 END) / 60 AS educational_minutes,
    SUM(CASE WHEN us.category = 'recreational' THEN us.duration_seconds ELSE 0 END) / 60 AS recreational_minutes,
    SUM(us.duration_seconds) / 60 AS total_minutes,
    COUNT(DISTINCT us.bundle_id) AS unique_apps_used,
    MIN(us.started_at) AS first_usage,
    MAX(us.ended_at) AS last_usage
FROM usage_sessions us
WHERE us.ended_at IS NOT NULL
GROUP BY us.child_id, us.date, us.device_id;

-- View: Current enforcement status per child
CREATE OR REPLACE VIEW current_enforcement_status AS
SELECT
    et.child_id,
    et.date,
    et.educational_minutes,
    et.required_educational_minutes,
    et.recreational_minutes_available,
    et.recreational_minutes_used,
    et.requirement_met,
    up.full_name AS child_name,
    d.device_name,
    d.last_sync
FROM earned_time et
JOIN user_profiles up ON et.child_id = up.id
LEFT JOIN devices d ON et.child_id = d.child_id AND d.is_active = true
WHERE et.date = CURRENT_DATE;

-- View: Family overview with member counts
CREATE OR REPLACE VIEW family_overview AS
SELECT
    f.id,
    f.name,
    f.invite_code,
    f.created_at,
    COUNT(DISTINCT CASE WHEN fm.role = 'child' THEN fm.user_id END) AS child_count,
    COUNT(DISTINCT CASE WHEN fm.role IN ('parent', 'admin') THEN fm.user_id END) AS parent_count,
    COUNT(DISTINCT d.id) AS device_count
FROM families f
LEFT JOIN family_members fm ON f.id = fm.family_id
LEFT JOIN devices d ON f.id = d.family_id AND d.is_active = true
GROUP BY f.id, f.name, f.invite_code, f.created_at;

-- Grant access to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

COMMENT ON TABLE public.user_profiles IS 'Extended user profile information';
COMMENT ON TABLE public.families IS 'Family account container';
COMMENT ON TABLE public.family_members IS 'Links users to families with roles';
COMMENT ON TABLE public.devices IS 'Child devices registered in the system';
COMMENT ON TABLE public.apps IS 'Catalog of apps with family-specific categorization';
COMMENT ON TABLE public.screen_time_rules IS 'Daily screen time requirements and schedules';
COMMENT ON TABLE public.usage_sessions IS 'App usage tracking data from child devices';
COMMENT ON TABLE public.earned_time IS 'Daily earned recreational time tracking';
COMMENT ON TABLE public.parent_commands IS 'Remote commands from parent to child device';
COMMENT ON TABLE public.activity_logs IS 'Audit trail for important actions';
