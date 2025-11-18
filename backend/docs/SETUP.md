# Backend Setup Guide

This guide will help you set up the Supabase backend for Screen Time Balancer.

## Prerequisites

- Node.js 18+ installed
- A Supabase account (free tier available at [supabase.com](https://supabase.com))
- Basic familiarity with PostgreSQL and REST APIs

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Enter project details:
   - **Name**: screen-time-balancer (or your preferred name)
   - **Database Password**: Generate a strong password (save it securely)
   - **Region**: Choose closest to your users
   - **Plan**: Free tier is sufficient for MVP
4. Click "Create new project" and wait for setup to complete

## Step 2: Install Supabase CLI

```bash
npm install -g supabase
```

Verify installation:
```bash
supabase --version
```

## Step 3: Link Local Project to Supabase

Navigate to the backend directory:
```bash
cd backend
```

Login to Supabase:
```bash
supabase login
```

Link your project:
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

You can find your project ref in the Supabase dashboard URL: `https://app.supabase.com/project/YOUR_PROJECT_REF`

## Step 4: Run Database Migrations

Push the migrations to your Supabase project:

```bash
supabase db push
```

This will:
- Create all database tables
- Set up Row Level Security policies
- Create helper functions and triggers
- Set up database views

Verify the migration:
```bash
supabase db diff
```

Should show no differences if migrations applied successfully.

## Step 5: Deploy Edge Functions

Deploy the daily reset function:

```bash
supabase functions deploy daily-reset
```

Set up a cron job to run daily at midnight (in Supabase Dashboard):
1. Go to Database → Cron Jobs
2. Add new job:
   - **Schedule**: `0 0 * * *` (midnight daily)
   - **Function**: `daily-reset`

Alternatively, use Supabase Dashboard → Edge Functions → daily-reset → Schedule

## Step 6: Get API Credentials

From your Supabase project dashboard:

1. Go to **Settings** → **API**
2. Copy the following values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: Used by client apps
   - **service_role key**: Used for admin operations (keep secret!)

You'll need these for iOS app configuration.

## Step 7: Configure Authentication

1. Go to **Authentication** → **Settings**
2. Enable email authentication:
   - Email provider: Enabled
   - Confirm email: Disabled (for MVP, enable in production)
   - Secure email change: Enabled

3. (Optional) Enable OAuth providers:
   - **Apple**: For Sign in with Apple
   - **Google**: For Google Sign-In
   - Follow Supabase docs for provider setup

4. Set up email templates:
   - Go to **Authentication** → **Email Templates**
   - Customize signup and password reset emails

## Step 8: Test the Backend

### Using Supabase Dashboard

1. Go to **Table Editor**
2. Verify all tables are created:
   - user_profiles
   - families
   - family_members
   - devices
   - apps
   - screen_time_rules
   - usage_sessions
   - earned_time
   - parent_commands
   - activity_logs

### Using SQL Editor

Run a test query:

```sql
-- Check if functions are created
SELECT proname FROM pg_proc
WHERE proname IN ('generate_invite_code', 'calculate_earned_time', 'update_updated_at_column');

-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

### Test API Endpoints

Using curl or Postman:

```bash
# Replace with your Supabase URL and anon key
SUPABASE_URL="https://xxxxx.supabase.co"
ANON_KEY="your-anon-key"

# Test health check
curl "$SUPABASE_URL/rest/v1/" \
  -H "apikey: $ANON_KEY"

# Should return OpenAPI spec or success response
```

## Step 9: Seed Test Data (Optional)

Create test data for development:

```sql
-- Create test parent user (do this via Supabase Auth UI or signup endpoint)
-- Then insert profile

INSERT INTO public.user_profiles (id, email, full_name, role)
VALUES
  ('parent-user-uuid', 'parent@test.com', 'Test Parent', 'parent'),
  ('child-user-uuid', 'child@test.com', 'Test Child', 'child');

-- Create test family
INSERT INTO public.families (name, created_by)
VALUES ('Test Family', 'parent-user-uuid');

-- Get the family ID and invite code
SELECT id, invite_code FROM public.families WHERE name = 'Test Family';

-- Add family members
INSERT INTO public.family_members (family_id, user_id, role)
VALUES
  ('family-uuid', 'parent-user-uuid', 'admin'),
  ('family-uuid', 'child-user-uuid', 'child');

-- Create a test rule
INSERT INTO public.screen_time_rules (family_id, name, required_educational_minutes, max_recreational_minutes)
VALUES ('family-uuid', 'Default Rule', 30, 120);

-- Add test apps
INSERT INTO public.apps (family_id, bundle_id, app_name, category)
VALUES
  ('family-uuid', 'com.apple.mobilesafari', 'Safari', 'utility'),
  ('family-uuid', 'com.apple.iBooks', 'Books', 'educational'),
  ('family-uuid', 'com.youtube.app', 'YouTube', 'recreational');
```

## Step 10: Monitor and Maintain

### View Logs

Check Edge Function logs:
```bash
supabase functions logs daily-reset
```

### Monitor Database

Use Supabase Dashboard → Database → Reports to monitor:
- Query performance
- Table sizes
- Active connections

### Backup Database

Automated backups are included in Supabase. To create manual backup:

```bash
supabase db dump -f backup.sql
```

## Environment Variables for iOS Apps

Create a configuration file with these values for your iOS apps:

```swift
// Config.swift
enum Config {
    static let supabaseURL = "https://xxxxx.supabase.co"
    static let supabaseAnonKey = "your-anon-key-here"
}
```

**Important**: Never commit the service_role key to version control!

## Troubleshooting

### Migration Fails

```bash
# Reset local database
supabase db reset

# Re-run migrations
supabase db push
```

### RLS Policies Not Working

Check policies in SQL Editor:
```sql
SELECT * FROM pg_policies WHERE tablename = 'your_table_name';
```

### Realtime Not Working

Verify realtime is enabled for tables:
```sql
SELECT tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
```

### Connection Issues

- Verify project is not paused (free tier pauses after inactivity)
- Check API keys are correct
- Ensure network allows connections to Supabase

## Scaling Considerations

### Free Tier Limits
- 500 MB database storage
- 2 GB bandwidth/month
- 50,000 monthly active users
- 200 concurrent realtime connections

### When to Upgrade

Upgrade to Supabase Pro ($25/month) when:
- Database exceeds 500 MB
- Need more bandwidth
- Require point-in-time recovery
- Need production-ready SLAs

### Performance Optimization

1. **Add Indexes**: Monitor slow queries and add indexes
   ```sql
   CREATE INDEX idx_custom ON table_name(column_name);
   ```

2. **Partition Large Tables**: Partition usage_sessions by date
   ```sql
   -- See PostgreSQL partitioning docs
   ```

3. **Archive Old Data**: Move old usage_sessions to cold storage

## Security Checklist

- [ ] Row Level Security enabled on all tables
- [ ] Service role key stored securely (never in client apps)
- [ ] Email confirmations enabled (production)
- [ ] Rate limiting configured (Supabase Dashboard → Authentication → Rate Limits)
- [ ] CORS configured for your domains only
- [ ] Regular security audits of RLS policies
- [ ] Database backups verified

## Next Steps

- Configure iOS Parent app with Supabase credentials
- Configure iOS Child app with Supabase credentials
- Test authentication flow end-to-end
- Test family linking and device registration
- Deploy Edge Functions to production

## Support

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Discord**: https://discord.supabase.com
- **Project Issues**: Create issue in repository

---

**Last Updated**: 2024-11-18
