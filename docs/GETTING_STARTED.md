// Getting Started Guide
# Getting Started with Screen Time Balancer

A comprehensive guide to get Screen Time Balancer up and running for development and testing.

## Prerequisites

Before you begin, ensure you have:

- **macOS** 13.0 or later (for iOS development)
- **Xcode** 15.0 or later
- **iOS Device** running iOS 17.0+ (Screen Time API requires real device)
- **Apple Developer Account** (required for Screen Time API)
- **Supabase Account** (free tier available)
- **Node.js** 18+ (for Supabase CLI)
- **Git** (for version control)

## Quick Start (5 Minutes)

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/screen-time-balancer.git
cd screen-time-balancer
```

### 2. Backend Setup

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Navigate to backend
cd backend

# Link to your Supabase project
# (Create project first at supabase.com if you haven't)
supabase link --project-ref YOUR_PROJECT_REF

# Apply database migrations
supabase db push

# Deploy edge functions
supabase functions deploy daily-reset
```

### 3. Configure iOS Apps

**Get Supabase Credentials:**
1. Go to your Supabase Dashboard
2. Settings → API
3. Copy:
   - Project URL: `https://xxxxx.supabase.co`
   - anon/public key: `eyJhbG...`

**Update Parent App Config:**
```swift
// ios-parent/ScreenTimeParent/App/Config.swift

enum Config {
    static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = "YOUR_ANON_KEY"
}
```

**Update Child App Config:**
```swift
// ios-child/ScreenTimeChild/App/Config.swift

enum Config {
    static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = "YOUR_ANON_KEY"
}
```

### 4. Open and Run

**Parent App:**
```bash
cd ios-parent
open ScreenTimeParent.xcodeproj

# In Xcode:
# 1. Select your development team
# 2. Select target device (iPhone/iPad)
# 3. Click Run (⌘R)
```

**Child App:**
```bash
cd ios-child
open ScreenTimeChild.xcodeproj

# In Xcode:
# 1. Select your development team
# 2. Select target device (iPhone/iPad)
# 3. Click Run (⌘R)
```

## Detailed Setup

### Backend Configuration

#### Creating a Supabase Project

1. **Sign Up:**
   - Visit [supabase.com](https://supabase.com)
   - Click "Start your project"
   - Sign up with GitHub, Google, or email

2. **Create Project:**
   ```
   Organization: Create new (if first project)
   Project Name: screen-time-balancer-dev
   Database Password: [Generate strong password - save this!]
   Region: [Select closest to you]
   Pricing Plan: Free
   ```

3. **Wait for Setup:**
   - Takes 2-3 minutes
   - You'll see a progress indicator

4. **Get Credentials:**
   - Dashboard → Settings → API
   - Copy Project URL and anon key

#### Running Migrations

```bash
cd backend

# Link project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push

# Verify tables created
supabase db diff  # Should show no differences
```

**Verify in Dashboard:**
1. Go to Supabase Dashboard
2. Table Editor
3. You should see tables:
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

#### Setting Up Authentication

**In Supabase Dashboard:**

1. **Authentication → Settings**
2. **Enable Email Provider:**
   - Email: Enabled
   - Confirm email: Disabled (for development)
   - Secure email change: Enabled

3. **Site URL:**
   ```
   http://localhost:3000
   ```

4. **Redirect URLs:**
   ```
   com.yourcompany.screentimeparent://
   com.yourcompany.screentimechild://
   ```

### iOS Development Setup

#### Installing Dependencies

Both iOS projects use Swift Package Manager (SPM):

**Parent App:**
```bash
cd ios-parent

# Dependencies are specified in Package.swift
# Xcode will automatically resolve them
```

**Child App:**
```bash
cd ios-child

# Dependencies are specified in Package.swift
# Xcode will automatically resolve them
```

**Key Dependencies:**
- [supabase-swift](https://github.com/supabase/supabase-swift): Supabase client
- FamilyControls: Apple's Screen Time API (built-in)

#### Xcode Configuration

**For Both Apps:**

1. **Open Project:**
   - Double-click `.xcodeproj` file
   - Or: `open ScreenTimeParent.xcodeproj`

2. **Select Target:**
   - Click project name in top bar
   - Select "ScreenTimeParent" or "ScreenTimeChild"

3. **Signing & Capabilities:**
   - General tab
   - Team: Select your Apple Developer account
   - Bundle Identifier: Update to your own
     - Parent: `com.yourcompany.screentimeparent`
     - Child: `com.yourcompany.screentimechild`

4. **Add Capabilities (Child App Only):**
   - Signing & Capabilities tab
   - + Capability
   - Add "Family Controls"

5. **Select Device:**
   - Top bar: Select a connected iOS device
   - Screen Time API requires real device (not simulator)

6. **Build and Run:**
   - Product → Run (⌘R)
   - Or: Click Play button

### Testing the Complete Flow

#### 1. Create Parent Account

**On Parent App:**
1. Launch app
2. Click "Sign Up"
3. Enter:
   - Full Name: "John Doe"
   - Email: "parent@test.com"
   - Password: "password123" (8+ chars)
4. Click "Sign Up"

**You should see:**
- "Dashboard" screen
- Empty state: "No Children Added"

#### 2. Create Family

**In Parent App:**
1. Go to "Family" tab
2. Click "Create Family"
3. Enter name: "Smith Family"
4. Click "Create"

**You'll receive:**
- 8-character invite code (e.g., "ABC123XY")
- Save this code!

#### 3. Create Child Account

**On Child Device:**
1. Create child account via Supabase Dashboard:
   - Authentication → Users → Add User
   - Email: "child@test.com"
   - Password: "password123"
   - Metadata: `{"role": "child", "full_name": "Emma"}`

2. **Or** use Parent App to send invite (future feature)

#### 4. Join Family (Child)

**On Child App:**
1. Sign in with child@test.com
2. Click "Have an invite code?"
3. Enter the 8-character code from step 2
4. Click "Join Family"

**Verification:**
- Parent app "Family" tab should show child
- Child app dashboard should load

#### 5. Create Screen Time Rule

**In Parent App:**
1. Go to "Rules" tab
2. Click "New Rule"
3. Configure:
   - Name: "School Days"
   - Educational requirement: 30 minutes
   - Max recreational: 90 minutes
   - Active days: All days
4. Save

#### 6. Categorize Apps

**In Parent App:**
1. Go to "Apps" tab
2. Click "Add App"
3. Select apps and categorize:
   - Books, Khan Academy → Educational
   - Games, YouTube → Recreational
4. Save

#### 7. Test Enforcement (Child App)

**On Child Device:**
1. Check dashboard:
   - Should show 0/30 minutes educational time
   - Status: "Recreational Apps Locked"

2. Open an educational app (e.g., Books)
3. Use for 30+ minutes
4. Return to Screen Time Child app
5. Status should update to "Unlocked"

#### 8. Monitor Usage (Parent App)

**In Parent App:**
1. Dashboard tab
2. View child's progress:
   - Educational time: 30 minutes
   - Recreational time: Available
   - Status: Requirement met

## Development Workflow

### Running Backend Locally

```bash
cd backend

# Start local Supabase (optional, for development)
supabase start

# This starts:
# - PostgreSQL
# - GoTrue (Auth)
# - PostgREST (API)
# - Storage
# - Realtime

# Access local dashboard at http://localhost:54323
```

### Making Backend Changes

**Database Schema Changes:**

```bash
# Create new migration
supabase migration new add_new_feature

# Edit migration file in backend/supabase/migrations/

# Apply migration
supabase db push

# Verify
supabase db diff
```

**Edge Function Changes:**

```bash
# Edit function in backend/supabase/functions/

# Deploy
supabase functions deploy function-name
```

### iOS Development

**Hot Reload:**
- SwiftUI supports live previews
- Changes reflect immediately in Xcode preview

**Debugging:**
```swift
// Add breakpoints by clicking line number gutter
// View console logs: View → Debug Area → Show Debug Area
print("Debug message: \(variable)")
```

**Testing:**
```bash
# Run unit tests
⌘U in Xcode

# Or via command line
xcodebuild test -scheme ScreenTimeParent -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Troubleshooting

### Backend Issues

**"Project not found" error:**
```bash
# Verify you're linked to correct project
supabase status

# Re-link if needed
supabase link --project-ref YOUR_PROJECT_REF
```

**Migration fails:**
```bash
# Reset local database
supabase db reset

# Re-apply migrations
supabase db push
```

**RLS policy blocking requests:**
- Check policies in Dashboard → Authentication → Policies
- Verify user has correct role (parent/child)
- Check foreign key relationships

### iOS Issues

**"Supabase URL not configured" warning:**
- Update `Config.swift` with your actual Supabase URL
- Clean build folder (⌘⇧K)
- Rebuild (⌘B)

**Family Controls not working:**
- Must run on real device (not simulator)
- Requires Apple Developer account
- Check that capability is added in Xcode
- Request authorization in app

**App crashes on launch:**
- Check Console logs (⌘⇧C in Xcode)
- Verify Supabase credentials are correct
- Check network connectivity

**Build fails:**
```bash
# Clean build folder
Product → Clean Build Folder (⌘⇧K)

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
Product → Build (⌘B)
```

## Next Steps

### For Development

1. **Implement remaining features:**
   - Family member management UI
   - App categorization flow
   - Rules creation/editing UI
   - Usage reports and analytics
   - Push notifications

2. **Add device activity monitoring:**
   - Implement DeviceActivityMonitor extension
   - Track actual app usage
   - Sync usage data to backend

3. **Enhance enforcement:**
   - Implement app blocking with Screen Time API
   - Add time windows and schedules
   - Support multiple rules per child

### For Production

1. **Security hardening:**
   - Enable email confirmation
   - Add rate limiting
   - Implement proper token refresh
   - Add biometric authentication

2. **Testing:**
   - Write comprehensive unit tests
   - Integration tests for API flows
   - UI tests for critical paths
   - Beta testing with real families

3. **Deployment:**
   - Follow [DEPLOYMENT.md](DEPLOYMENT.md)
   - Submit to TestFlight
   - Gather feedback
   - Submit to App Store

## Resources

### Documentation

- [Architecture](ARCHITECTURE.md)
- [API Reference](API.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Backend Setup](../backend/docs/SETUP.md)

### External Resources

- [Supabase Docs](https://supabase.com/docs)
- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Screen Time API](https://developer.apple.com/documentation/familycontrols)

### Support

- GitHub Issues: [Create Issue](https://github.com/yourusername/screen-time-balancer/issues)
- Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- Apple Developer Forums: [developer.apple.com/forums](https://developer.apple.com/forums)

## FAQ

**Q: Can I use the simulator?**
A: Parent app works on simulator, but Child app requires a real device for Screen Time API.

**Q: Do I need a paid Apple Developer account?**
A: Yes, for Screen Time API and TestFlight distribution.

**Q: Can I use a different backend?**
A: Yes, but you'll need to implement the API layer. Supabase is recommended for ease of use.

**Q: How much does Supabase cost?**
A: Free tier is sufficient for MVP and testing. Pro tier ($25/month) for production.

**Q: Can I customize the app?**
A: Absolutely! The codebase is modular and well-documented.

**Q: Is this production-ready?**
A: This is an MVP. Additional features, testing, and hardening recommended for production.

---

**Need help?** Create an issue on GitHub or reach out to the community!

**Last Updated:** 2024-11-18
