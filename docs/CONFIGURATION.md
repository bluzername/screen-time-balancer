# Screen Time Balancer - Configuration Guide

This guide explains how to configure the Screen Time Balancer apps for development and production.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Environment Variables](#environment-variables)
3. [iOS Configuration](#ios-configuration)
4. [Security Best Practices](#security-best-practices)
5. [Troubleshooting](#troubleshooting)

---

## Quick Start

### 1. Get Supabase Credentials

1. Go to your Supabase project: https://app.supabase.com
2. Navigate to **Settings** → **API**
3. Copy the following values:
   - **Project URL** (e.g., `https://abcdefgh.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 2. Configure Environment Variables

```bash
# Copy the template
cp .env.template .env

# Edit .env with your credentials
nano .env
```

Replace the placeholder values:

```bash
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Configure iOS Apps

#### Option A: Using Environment Variables (Recommended)

The apps will automatically read from environment variables if they're set.

```bash
# Set environment variables
export SUPABASE_URL="https://your-project-ref.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"

# Run Xcode from the terminal to inherit environment
open ios-parent/ScreenTimeParent.xcodeproj
```

#### Option B: Manual Configuration

1. **Parent App:**
   ```bash
   cd ios-parent/ScreenTimeParent/App
   cp Config-Template.swift Config.swift
   nano Config.swift
   ```

   Replace the placeholders in `Config.swift`:
   ```swift
   static let supabaseURL: URL = {
       guard let url = URL(string: "https://your-actual-project.supabase.co") else {
           fatalError("Invalid Supabase URL configuration")
       }
       return url
   }()

   static let supabaseAnonKey: String = {
       return "your-actual-anon-key-here"
   }()
   ```

2. **Child App:** Repeat the same steps for the child app:
   ```bash
   cd ios-child/ScreenTimeChild/App
   cp Config-Template.swift Config.swift
   nano Config.swift
   ```

### 4. Verify Configuration

Build and run either app. Check the console for:

```
================================
Screen Time Parent - Configuration
================================
Environment: development
App Version: 1.0 (1)

Supabase:
- URL: https://your-project.supabase.co
- Key: eyJhbGciOiJIUzI1NiI...(hidden)
================================
```

If you see warnings about configuration, your credentials are not properly set.

---

## Environment Variables

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SUPABASE_URL` | (required) | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | (required) | Your Supabase anonymous key |
| `APP_ENVIRONMENT` | `development` | Environment: development, staging, production |
| `ENABLE_LOGGING` | `true` (debug), `false` (release) | Enable console logging |
| `ENABLE_ANALYTICS` | `false` (debug), `true` (release) | Enable analytics |
| `CHILD_SYNC_INTERVAL_SECONDS` | `300` | How often child app syncs (5 minutes) |
| `CHILD_HEARTBEAT_INTERVAL_SECONDS` | `30` | Heartbeat interval (30 seconds) |
| `PARENT_SYNC_INTERVAL_SECONDS` | `60` | How often parent app syncs (1 minute) |
| `PARENT_ENABLE_REALTIME` | `true` | Enable realtime subscriptions |
| `FEATURE_OFFLINE_MODE` | `true` | Enable offline functionality |

### Setting Environment Variables

#### macOS (for Xcode)

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
# Screen Time Balancer
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
export APP_ENVIRONMENT="development"
```

Then:
```bash
source ~/.zshrc
```

#### Launch Xcode from Terminal

To ensure Xcode inherits environment variables:

```bash
# Always launch Xcode from terminal
open ios-parent/ScreenTimeParent.xcodeproj
```

---

## iOS Configuration

### Build Schemes

Create different build schemes for each environment:

1. Open Xcode project
2. Go to **Product** → **Scheme** → **Edit Scheme**
3. Select **Run** → **Arguments**
4. Add environment variables:
   - `SUPABASE_URL`: `$(SUPABASE_URL)`
   - `APP_ENVIRONMENT`: `development`

### Info.plist

Some configuration values are in `Info.plist`:

- Bundle Identifier
- Version/Build Number
- Required capabilities (FamilyControls, BackgroundModes)
- Usage descriptions

**Do not** put secrets in Info.plist - it's included in the app bundle!

---

## Security Best Practices

### ✅ DO

1. **Use Environment Variables** for all secrets
2. **Never commit** `Config.swift` or `.env` to version control
3. **Use different keys** for development and production
4. **Rotate keys regularly** (every 90 days)
5. **Use Row Level Security** (RLS) in Supabase
6. **Keep service role key secret** - never use in client apps

### ❌ DON'T

1. **Don't hardcode** credentials in source code
2. **Don't commit** secrets to Git
3. **Don't share** production keys in chat/email
4. **Don't use** service role key in mobile apps
5. **Don't expose** API keys in screenshots or demos

### Key Security

The **anon key** is safe to use in client apps because:
- It's meant to be public
- Row Level Security (RLS) protects data
- It only has limited permissions

The **service role key** should **NEVER** be used in client apps:
- It bypasses RLS
- It has full admin access
- It should only be used on secure servers

---

## Troubleshooting

### "Supabase URL not configured" Error

**Problem:** App shows warning on launch

**Solution:**
1. Check if `Config.swift` exists (not `Config-Template.swift`)
2. Verify URL doesn't contain "your-project-ref"
3. Ensure URL starts with `https://`
4. Check environment variables are set

### "Invalid Supabase anonymous key" Error

**Problem:** Authentication fails

**Solution:**
1. Verify you copied the full key (should be very long, ~200+ characters)
2. Make sure you're using the **anon key**, not service role key
3. Check for trailing spaces or newlines
4. Regenerate key in Supabase dashboard if needed

### Environment Variables Not Working

**Problem:** App still uses placeholder values

**Solution:**
1. Launch Xcode from terminal: `open MyApp.xcodeproj`
2. Verify variables are exported: `env | grep SUPABASE`
3. Clean build folder: **Product** → **Clean Build Folder**
4. Restart Xcode

### Network Errors

**Problem:** "Network error" when making requests

**Solution:**
1. Check internet connection
2. Verify Supabase URL is correct
3. Check if project is paused (free tier limitation)
4. Review Supabase dashboard for outages

---

## Multiple Environments

For production deployment, create separate configurations:

### Development
```bash
export SUPABASE_URL="https://dev-project.supabase.co"
export SUPABASE_ANON_KEY="dev-key-here"
export APP_ENVIRONMENT="development"
```

### Staging
```bash
export SUPABASE_URL="https://staging-project.supabase.co"
export SUPABASE_ANON_KEY="staging-key-here"
export APP_ENVIRONMENT="staging"
```

### Production
```bash
export SUPABASE_URL="https://prod-project.supabase.co"
export SUPABASE_ANON_KEY="prod-key-here"
export APP_ENVIRONMENT="production"
```

---

## Next Steps

1. ✅ Configure credentials
2. ✅ Verify configuration
3. ✅ Test authentication
4. ✅ Deploy to TestFlight
5. ✅ Submit to App Store

For deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).
