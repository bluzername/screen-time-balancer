# Xcode Setup and Testing Guide
## Screen Time Balancer - Complete Setup Instructions

This guide will walk you through every step needed to get the Screen Time Balancer app running in Xcode, from initial setup through simulator testing and physical device deployment.

**Time Required:** 30-60 minutes (first time)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Initial Setup](#part-1-initial-setup)
3. [Part 2: Supabase Configuration](#part-2-supabase-configuration)
4. [Part 3: Xcode Project Setup](#part-3-xcode-project-setup)
5. [Part 4: Simulator Testing](#part-4-simulator-testing)
6. [Part 5: Physical Device Testing](#part-5-physical-device-testing)
7. [Troubleshooting](#troubleshooting)
8. [Common Errors](#common-errors)

---

## Prerequisites

### Required Software

1. **macOS Ventura or later**
   - Check: Click Apple menu → About This Mac

2. **Xcode 15.0 or later**
   - Install from Mac App Store (free)
   - Download size: ~10GB
   - Installation time: 30-60 minutes
   - After install, open Xcode once to complete setup

3. **Command Line Tools**
   - Open Terminal
   - Run: `xcode-select --install`
   - Click "Install" when prompted

4. **Git** (already installed if you have Xcode)
   - Verify: `git --version` in Terminal

### Required Accounts

1. **Apple Developer Account** (free tier is fine)
   - Sign up at: https://developer.apple.com
   - Required for device testing (not simulator)

2. **Supabase Account** (free tier is fine)
   - Sign up at: https://supabase.com
   - Required for backend

### Optional but Recommended

- **GitHub Desktop** - Easier than command line
- **Fork** or **Tower** - Git GUI clients
- **TestFlight** - For beta testing (comes with Xcode)

---

## Part 1: Initial Setup

### Step 1.1: Clone the Repository

**Option A: Using Terminal (Recommended)**

```bash
# Navigate to where you want the project
cd ~/Documents

# Clone the repository
git clone https://github.com/bluzername/screen-time-balancer.git

# Enter the directory
cd screen-time-balancer

# Verify you're on the right branch
git branch
# Should show: claude/parental-control-app-mvp-01FNBERWPGLVyjyNpsthbRRD
```

**Option B: Using GitHub Desktop**

1. Open GitHub Desktop
2. File → Clone Repository
3. URL tab → Paste: `https://github.com/bluzername/screen-time-balancer.git`
4. Choose location (e.g., Documents)
5. Click "Clone"

### Step 1.2: Verify Project Structure

Open Finder and navigate to the cloned folder. You should see:

```
screen-time-balancer/
├── ios-parent/              ← Parent app folder
│   └── ScreenTimeParent/
│       ├── ScreenTimeParent.xcodeproj  ← Open this
│       └── ...
├── ios-child/               ← Child app folder
│   └── ScreenTimeChild/
│       ├── ScreenTimeChild.xcodeproj   ← Open this
│       └── ...
├── supabase/               ← Backend configuration
├── docs/                   ← Documentation
└── README.md
```

**Important:** There are TWO separate apps:
- **Parent app** - For parents to set rules
- **Child app** - For children's devices

---

## Part 2: Supabase Configuration

### Step 2.1: Create Supabase Project

1. Go to https://supabase.com
2. Click "Start your project"
3. Sign in with GitHub (recommended)
4. Click "New project"
5. Fill in:
   - **Name:** `screen-time-balancer` (or your choice)
   - **Database Password:** Generate a strong password (SAVE THIS!)
   - **Region:** Choose closest to you
   - **Pricing Plan:** Free
6. Click "Create new project"
7. Wait 2-3 minutes for setup

### Step 2.2: Get Your Credentials

Once the project is ready:

1. Click "Settings" (gear icon in sidebar)
2. Click "API" under Configuration
3. You'll see:
   - **Project URL** - Looks like `https://xxxxxxxxxxxxx.supabase.co`
   - **anon public** key - Long string starting with `eyJ...`

**IMPORTANT: Copy both of these - you'll need them soon!**

### Step 2.3: Setup Database Schema

1. In Supabase dashboard, click "SQL Editor" (in sidebar)
2. Click "New query"
3. Copy the SQL schema from `supabase/migrations/schema.sql` in your project
4. Paste into the SQL editor
5. Click "Run" (or press Cmd+Enter)
6. You should see "Success. No rows returned"

**Note:** If you see errors, check the troubleshooting section.

### Step 2.4: Enable Realtime

1. Click "Database" in sidebar
2. Click "Replication"
3. Enable replication for these tables:
   - `usage_sessions`
   - `earned_time`
   - `screen_time_rules`
   - `devices`
4. Click "Save" for each

### Step 2.5: Create Environment Files

Open Terminal in the project directory:

```bash
# Navigate to project root
cd ~/Documents/screen-time-balancer

# Copy the template
cp .env.template .env

# Edit the file (using nano, vim, or any text editor)
nano .env
```

Fill in your Supabase credentials:

```bash
# Supabase Configuration
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxxxxxxxxxxxxxxxxxxxxx

# App Configuration
PARENT_ENABLE_REALTIME=true
PARENT_ENABLE_LOGGING=true
CHILD_ENABLE_REALTIME=true
CHILD_ENABLE_LOGGING=true
```

**Save the file:**
- In nano: Press Ctrl+X, then Y, then Enter
- In vim: Press Esc, type `:wq`, press Enter

---

## Part 3: Xcode Project Setup

We'll setup both apps (Parent and Child) separately.

### Step 3.1: Setup Parent App

#### 3.1.1: Open Project

1. Double-click: `ios-parent/ScreenTimeParent/ScreenTimeParent.xcodeproj`
2. Xcode will open (first time may take a minute)

#### 3.1.2: Configure Signing

1. In Xcode, select the project (blue icon) in the left sidebar
2. Select "ScreenTimeParent" target (under TARGETS)
3. Click "Signing & Capabilities" tab
4. Under "Signing":
   - Check "Automatically manage signing"
   - Team: Select your Apple ID (if not there, add it: Xcode → Settings → Accounts → + → Apple ID)
   - Bundle Identifier: Change to something unique:
     - Original: `com.screentimeparent.app`
     - Change to: `com.YOURNAME.screentimeparent` (e.g., `com.john.screentimeparent`)

#### 3.1.3: Add Dependencies

1. In Xcode, select the project in left sidebar
2. Click "Package Dependencies" tab
3. Click the "+" button
4. Add Supabase SDK:
   - **URL:** `https://github.com/supabase/supabase-swift`
   - **Version:** Up to Next Major: 2.0.0
   - Click "Add Package"
   - Check "Supabase" library
   - Click "Add Package"

**Wait for dependencies to download (2-5 minutes)**

#### 3.1.4: Configure Environment Variables in Xcode

Since iOS doesn't support `.env` files directly, we need to configure the app:

1. Open `ios-parent/ScreenTimeParent/App/Config.swift`
2. Find these lines (around line 20-30):

```swift
static let supabaseURL: URL = {
    if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
       let url = URL(string: urlString) {
        return url
    }
    // TEMPORARY: Replace this with your actual URL
    guard let url = URL(string: "https://your-project-ref.supabase.co") else {
        fatalError("Invalid Supabase URL configuration")
    }
    return url
}()
```

3. Replace `"https://your-project-ref.supabase.co"` with YOUR Supabase URL
4. Do the same for `supabaseAnonKey` (around line 40):

```swift
static let supabaseAnonKey: String = {
    if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
        return key
    }
    // TEMPORARY: Replace this with your actual key
    return "eyJxxxx-your-actual-key-here"
}()
```

5. Press Cmd+S to save

**IMPORTANT:** This is temporary for testing. For production, use proper environment variable injection.

#### 3.1.5: Verify Build

1. Select a simulator: Click the device dropdown (top left, near "Run" button)
   - Choose: iPhone 15 Pro (iOS 17.x)
2. Press Cmd+B to build
3. Wait for build to complete (first build: 2-5 minutes)
4. Check for errors in bottom panel

**If you see errors, check the Troubleshooting section below.**

### Step 3.2: Setup Child App

Repeat the same steps for the child app:

#### 3.2.1: Open Project

1. Close current Xcode window (Cmd+Q)
2. Double-click: `ios-child/ScreenTimeChild/ScreenTimeChild.xcodeproj`

#### 3.2.2: Configure Signing

Same as parent app, but use different bundle identifier:
- Original: `com.screentimechild.app`
- Change to: `com.YOURNAME.screentimechild`

#### 3.2.3: Add Dependencies

Same as parent app - add Supabase Swift SDK.

#### 3.2.4: Configure Config.swift

1. Open `ios-child/ScreenTimeChild/App/Config.swift`
2. Replace the Supabase URL and key (same values as parent app)
3. Save with Cmd+S

#### 3.2.5: Add Screen Time Capability

**CRITICAL for child app:**

1. Select project → ScreenTimeChild target
2. Click "Signing & Capabilities"
3. Click "+ Capability" button
4. Search for "Family Controls"
5. Double-click to add it

**You should now see "Family Controls" in capabilities list.**

#### 3.2.6: Verify Build

1. Select simulator: iPhone 15 Pro
2. Press Cmd+B to build
3. Wait for completion

---

## Part 4: Simulator Testing

### Step 4.1: Run Parent App in Simulator

#### 4.1.1: Launch App

1. Open Parent app in Xcode (if not already open)
2. Select simulator: iPhone 15 Pro
3. Press Cmd+R to run (or click the Play ▶ button)
4. Simulator will launch (first time: 1-2 minutes)
5. App should appear on simulator screen

**Expected behavior:**
- App launches
- You see authentication screen
- No crashes

#### 4.1.2: Create Account (Parent)

1. In simulator, tap "Sign Up"
2. Fill in form:
   - **Full Name:** Test Parent
   - **Email:** parent@test.com
   - **Password:** TestPass123!
3. Tap "Create Account"

**Expected behavior:**
- No errors appear
- You're logged in
- You see dashboard/home screen

**If you see errors:**
- Check Supabase URL is correct in Config.swift
- Check Supabase anon key is correct
- Check network connection
- See Troubleshooting section

#### 4.1.3: Create a Family

1. On dashboard, tap "Create Family" (or "+" button)
2. Enter family name: "Test Family"
3. Tap "Create"

**Expected behavior:**
- Family created successfully
- You see an 8-character invite code (e.g., "ABC12345")

**IMPORTANT: Copy this invite code - you'll need it for child app!**

#### 4.1.4: Set Screen Time Rules

1. Navigate to "Rules" or "Settings"
2. Create a rule:
   - **Required Educational Minutes:** 60
   - **Child:** (select the child if any listed)
   - **Active:** ON
3. Save rule

### Step 4.2: Run Child App in Simulator

#### 4.2.1: Launch App

1. Close Parent app simulator (Cmd+Q on simulator)
2. Open Child app in Xcode
3. Select simulator: iPhone 15 Pro
4. Press Cmd+R to run

**Expected behavior:**
- Child app launches
- Authentication screen appears

#### 4.2.2: Create Child Account

1. Tap "Sign Up"
2. Fill in:
   - **Full Name:** Test Child
   - **Email:** child@test.com
   - **Password:** TestPass123!
3. Tap "Create Account"

#### 4.2.3: Join Family

1. You should see "Join Family" screen
2. Enter the invite code from parent app (e.g., "ABC12345")
3. Tap "Join Family"

**Expected behavior:**
- Success message
- Child is added to family
- Device is registered
- Dashboard appears

#### 4.2.4: Request Screen Time Permission

**IMPORTANT: This will FAIL on simulator** - Screen Time API only works on physical devices.

You'll see an error like:
```
Screen Time authorization failed: The operation couldn't be completed
```

**This is EXPECTED on simulator.** To test app blocking, you MUST use a physical device (see Part 5).

#### 4.2.5: Test What Works on Simulator

Even without Screen Time permissions, you can test:

✅ **Authentication:** Sign up, sign in, sign out
✅ **Family joining:** Enter invite code
✅ **Device registration:** View device info
✅ **Network calls:** All API calls work
✅ **UI navigation:** All screens work
✅ **Realtime updates:** Open parent app, make changes, see updates in child app

❌ **Cannot test on simulator:**
- App blocking (Screen Time API)
- App selection (FamilyActivityPicker)
- Actual enforcement

### Step 4.3: Test Realtime Updates

**Setup:**
1. Have BOTH parent and child apps open in separate simulator instances

**How to run two simulators:**

```bash
# In Terminal:
# Open first simulator
open -a Simulator

# Wait for it to load, then run parent app in Xcode

# Open second simulator (different device)
xcrun simctl boot "iPhone 15"
# Then run child app in Xcode, selecting the second simulator
```

**Test realtime sync:**

1. In parent app: Update a rule (change required minutes)
2. In child app: Watch for update (may take 1-2 seconds)
3. Verify the new value appears without refresh

**Expected behavior:**
- Changes in parent app appear in child app within 2 seconds
- No manual refresh needed
- Console shows: "✅ Realtime subscriptions active for family..."

---

## Part 5: Physical Device Testing

**Why use physical device?**
- Screen Time API (Family Controls) ONLY works on physical iOS devices
- Required to test app blocking, app selection, enforcement
- Simulator cannot request Screen Time permissions

### Step 5.1: Prepare Your Device

#### 5.1.1: Device Requirements

- iPhone or iPad running iOS 17.0 or later
- Not supervised by MDM (Mobile Device Management)
- Screen Time enabled
- Connected to Mac via USB cable

#### 5.1.2: Enable Developer Mode (iOS 16+)

1. On device: Settings → Privacy & Security → Developer Mode
2. Toggle ON
3. Restart device when prompted
4. After restart, confirm "Turn On Developer Mode"

#### 5.1.3: Trust Computer

1. Connect device to Mac with USB cable
2. On device: Pop-up "Trust This Computer?"
3. Tap "Trust"
4. Enter device passcode

### Step 5.2: Deploy Parent App to Device

#### 5.2.1: Select Device in Xcode

1. Open Parent app project in Xcode
2. Click device dropdown (top left)
3. Select your physical device (e.g., "John's iPhone")

**If device not showing:**
- Check USB cable is connected
- Check "Trust This Computer" was accepted
- Window → Devices and Simulators → Check device appears

#### 5.2.2: Build and Run

1. Press Cmd+R (or click Play ▶)
2. Xcode will:
   - Build app
   - Sign with your developer certificate
   - Install on device
   - Launch app

**First time:**
- May take 2-5 minutes
- Device may show "Verifying app..."
- App icon appears on home screen

#### 5.2.3: Trust Developer (First Time Only)

If app won't open on device:

1. On device: Settings → General → VPN & Device Management
2. Find your Apple ID / Developer App
3. Tap it
4. Tap "Trust [Your Name]"
5. Confirm

Now the app should launch!

#### 5.2.4: Test Parent App on Device

Same as simulator testing:
1. Create account
2. Create family
3. Copy invite code
4. Set rules

Everything should work the same as simulator.

### Step 5.3: Deploy Child App to Device

**IMPORTANT: Use a DIFFERENT device!**

The ideal setup:
- **Parent app:** On parent's iPhone/iPad
- **Child app:** On child's iPhone/iPad

**For testing with one device:**
You can install both apps on one device, but this won't reflect real-world usage.

#### 5.3.1: Select Device

1. Open Child app in Xcode
2. Select your device from dropdown
3. Press Cmd+R to build and run

#### 5.3.2: Grant Screen Time Permission

**This is the critical part that ONLY works on device:**

1. App launches
2. Tap "Sign Up" → Create child account
3. Enter family invite code → Tap "Join"
4. App will request Screen Time permission

**Expected prompt:**
```
"ScreenTimeChild" Would Like to Access Family Controls
This app will be able to monitor and restrict app usage.
```

5. Tap "Allow"
6. **Enter your device passcode** (this proves you're an adult)
7. App now has Screen Time permissions ✅

#### 5.3.3: Select Apps to Categorize

1. Navigate to app selection screen
2. Tap "Select Educational Apps"
3. FamilyActivityPicker sheet appears (Apple's native picker)
4. Select some apps (e.g., Books, Khan Academy, Duolingo)
5. Tap "Done"

6. Tap "Select Recreational Apps"
7. Select some apps (e.g., TikTok, Instagram, Games)
8. Tap "Done"

**Expected behavior:**
- Apps are saved
- You can see selections in the app
- Tokens are stored in App Groups

### Step 5.4: Test App Blocking

**Setup:**
1. Child app is open on device
2. Screen Time rule requires 60 minutes of educational app usage
3. Child has NOT yet used educational apps (0 minutes)

**Test:**

1. Go to device home screen
2. Try to open a recreational app (e.g., TikTok)

**Expected behavior:**
- App is blocked (screen with shield icon appears)
- Message: "App Limit" or similar
- Can't access the app

3. Open an educational app (e.g., Books)
4. Use it for 60+ minutes (or simulate time)
5. Try recreational app again

**Expected behavior:**
- App is now accessible
- No more block

**To simulate time for testing:**

You can manually update the database:

```sql
-- In Supabase SQL Editor:
UPDATE earned_time
SET educational_minutes = 60
WHERE child_id = 'YOUR_CHILD_UUID'
AND date = CURRENT_DATE;
```

Then in child app:
- Pull to refresh (or restart app)
- App should recalculate and unlock recreational apps

### Step 5.5: Test End-to-End Flow

**Complete workflow:**

1. **Parent (on parent device):**
   - Create family
   - Share invite code with child (text, email, or show code)
   - Set rule: 60 min educational required
   - Select educational apps (only parent can do this)
   - Select recreational apps to block

2. **Child (on child device):**
   - Download child app
   - Create account
   - Enter invite code
   - Grant Screen Time permission
   - Apps are automatically categorized (synced from parent)

3. **During the day:**
   - Child opens educational app (Books) → Works freely
   - Child opens recreational app (TikTok) → BLOCKED
   - Child uses Books for 60 minutes
   - EnforcementEngine recalculates every 2 minutes
   - After 60 min: Recreational apps unlock

4. **Parent monitoring (on parent device):**
   - Open parent app
   - See real-time usage updates (realtime subscriptions)
   - See "Educational: 60 min, Recreational: 15 min"
   - Can update rules anytime
   - Changes sync to child device within seconds

**Expected behavior:**
- ✅ All flows work seamlessly
- ✅ Realtime updates appear in parent app
- ✅ Rules enforce properly on child device
- ✅ No manual refresh needed

---

## Part 6: Advanced Testing

### Step 6.1: Test Error Handling

#### 6.1.1: Network Interruption

1. Open child app on device
2. Enable Airplane Mode
3. Try to join family / sign in

**Expected behavior:**
- Error message: "No internet connection. Please check your network settings"
- Retry button appears
- After 3 attempts, gives up with suggestion

4. Disable Airplane Mode
5. Tap Retry

**Expected behavior:**
- Automatic retry with exponential backoff
- Success after connection restored

#### 6.1.2: Invalid Input

1. Try to sign up with weak password: "123"

**Expected:**
- Real-time error: "Password must be at least 8 characters"
- Sign Up button disabled

2. Try invalid email: "notanemail"

**Expected:**
- Error: "Please enter a valid email address"

3. Try invalid invite code: "123"

**Expected:**
- Error: "Invite code must be 8 characters"

### Step 6.2: Test Realtime Sync

**With both apps open (parent on one device, child on another):**

#### Test 1: Rule Update
1. Parent: Change rule from 60 min to 30 min
2. Child: Should see update within 2 seconds
3. Console: "✅ Realtime subscriptions active"

#### Test 2: Usage Update
1. Child: Use educational app for 10 minutes
2. Parent: Should see usage update
3. Parent dashboard: "Educational: 10 min"

#### Test 3: Device Status
1. Child: Go offline (airplane mode)
2. Parent: Device shows "Offline" or "Last sync: 2 minutes ago"

### Step 6.3: Test Offline Behavior

**Simulate poor connection:**

1. Set device to 2G / Edge network (Settings → Developer → Network Link Conditioner)
2. Try various operations
3. App should work but slower
4. RetryManager should handle timeouts gracefully

---

## Part 7: Debugging Tips

### Enable Xcode Console Logging

1. In Xcode, run app
2. Bottom panel → Click "Show/Hide Debug Area" (Cmd+Shift+Y)
3. Console shows all print() statements

**Look for these logs:**

```
✅ Loaded rules and earned time
🔒 Locked 3 recreational apps
🔓 Unlocked recreational apps
✅ Realtime subscriptions active for family [UUID]
📡 Disconnected from realtime
```

### Enable Verbose Logging

In Config.swift, set:
```swift
static let enableLogging = true
```

This enables detailed logs from ErrorHandler and RetryManager.

### View Network Requests

1. Xcode → Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables → Add:
   - Name: `SUPABASE_LOG_LEVEL`
   - Value: `verbose`

Now you'll see all network requests in console.

### Inspect Database

In Supabase dashboard:
1. Click "Table Editor"
2. View data in tables:
   - `families` - All families
   - `family_members` - Who's in what family
   - `devices` - Registered devices
   - `screen_time_rules` - Active rules
   - `earned_time` - Daily educational minutes
   - `usage_sessions` - Session history

---

## Troubleshooting

### Common Issues

#### Issue 1: "Could not find Supabase module"

**Cause:** Swift Package not downloaded

**Fix:**
1. Xcode → File → Packages → Reset Package Caches
2. Wait 2 minutes
3. Build again (Cmd+B)

#### Issue 2: "Development team not found"

**Cause:** No Apple ID signed in

**Fix:**
1. Xcode → Settings → Accounts
2. Click "+"
3. Add Apple ID
4. Select the account in Signing & Capabilities

#### Issue 3: "App installation failed"

**Cause:** Device not trusted or developer mode off

**Fix:**
1. Check USB cable connected
2. On device: Settings → Privacy & Security → Developer Mode → ON
3. On device: Settings → General → VPN & Device Management → Trust developer

#### Issue 4: "Screen Time authorization failed"

**On simulator:**
- **Expected** - Screen Time doesn't work on simulator
- Use physical device

**On physical device:**
- Check device isn't supervised by MDM
- Check Screen Time is enabled: Settings → Screen Time
- Try restarting device

#### Issue 5: "Invalid Supabase credentials"

**Cause:** Wrong URL or key in Config.swift

**Fix:**
1. Open Supabase dashboard → Settings → API
2. Copy exact URL and anon key
3. Update Config.swift
4. Clean build: Xcode → Product → Clean Build Folder (Cmd+Shift+K)
5. Build again (Cmd+B)

#### Issue 6: Apps still showing after joining family

**Cause:** App categorization not synced

**Fix:**
1. Parent app: Make sure apps are selected
2. Child app: Pull to refresh
3. Check console for sync logs
4. Verify realtime is enabled in Config

#### Issue 7: "Too many requests" error

**Cause:** Rate limiter triggered

**Fix:**
- Wait 5 minutes
- Rate limit: 5 attempts per 5 minutes
- Or in Validators.swift, increase limit for testing

#### Issue 8: Build takes forever

**Cause:** Large dependency downloads

**Fix:**
- First build: 2-5 minutes is normal
- Check internet connection
- Xcode → Preferences → Locations → Derived Data → Delete
- Try again

#### Issue 9: Realtime not working

**Fix:**
1. Supabase dashboard → Database → Replication
2. Enable replication for all tables
3. Check Config.enableRealtime = true
4. Check console for connection logs

#### Issue 10: App crashes on launch

**Fix:**
1. Check console for crash log
2. Common causes:
   - Invalid Supabase URL (malformed)
   - Missing dependencies
   - Wrong iOS version (need 17+)
3. Clean build and retry

---

## Testing Checklist

Use this to verify everything works:

### Simulator Testing (Both Apps)

- [ ] Parent app builds without errors
- [ ] Child app builds without errors
- [ ] Parent: Sign up new account
- [ ] Parent: Sign in existing account
- [ ] Parent: Create family
- [ ] Parent: Get invite code
- [ ] Parent: Set screen time rules
- [ ] Child: Sign up new account
- [ ] Child: Join family with invite code
- [ ] Child: Device registered successfully
- [ ] Both: Realtime sync works
- [ ] Both: Sign out works

### Physical Device Testing (Both Apps)

- [ ] Parent app installs on device
- [ ] Child app installs on device
- [ ] Parent: All simulator tests pass
- [ ] Child: Screen Time permission granted
- [ ] Child: FamilyActivityPicker opens
- [ ] Child: Can select educational apps
- [ ] Child: Can select recreational apps
- [ ] Child: Recreational apps blocked initially
- [ ] Child: Educational apps work freely
- [ ] Child: Apps unlock after requirement met
- [ ] Parent: See real-time usage updates
- [ ] Parent: Rule changes sync to child
- [ ] Both: Offline mode works
- [ ] Both: Error handling works
- [ ] Both: Retry logic works on network issues

---

## Performance Benchmarks

**Target metrics:**

| Operation | Target | How to Measure |
|-----------|--------|----------------|
| App launch | <2s | Time from tap to dashboard |
| Sign in | <1s | Time from tap to success |
| Join family | <3s | Time from code entry to success |
| Load family details | <500ms | Time to display after tap |
| Realtime update latency | <2s | Time from parent change to child update |
| App unlock decision | <200ms | Time to unlock after requirement met |

**Measure in Xcode:**

1. Run app with Instruments:
   - Xcode → Product → Profile (Cmd+I)
   - Choose "Time Profiler"
   - Run app
   - Perform operations
   - Stop recording
   - Analyze timing

2. Check console logs:
   - Look for timing logs
   - Search for "⏱️" emoji in logs

---

## Next Steps After Testing

Once all tests pass:

1. **Write automated tests**
   - Unit tests for Validators
   - Integration tests for repositories
   - UI tests for critical flows

2. **Beta testing**
   - TestFlight setup
   - Invite beta testers
   - Collect feedback

3. **Performance optimization**
   - Profile with Instruments
   - Optimize slow operations
   - Reduce memory usage

4. **App Store preparation**
   - Screenshots
   - App description
   - Privacy policy
   - Support URL

---

## Quick Reference

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Build | Cmd+B |
| Run | Cmd+R |
| Stop | Cmd+. |
| Clean | Cmd+Shift+K |
| Show console | Cmd+Shift+Y |
| Show navigator | Cmd+0 |
| Quick help | Option+Click |

### Important Files

| File | Purpose |
|------|---------|
| Config.swift | Supabase credentials, app settings |
| ScreenTimeChildApp.swift | Child app entry point |
| ScreenTimeParentApp.swift | Parent app entry point |
| EnforcementEngineV2.swift | App blocking logic |
| RealtimeManager.swift | Live sync functionality |
| Validators.swift | Input validation |

### Important URLs

- **Supabase Dashboard:** https://app.supabase.com
- **Xcode Download:** https://apps.apple.com/app/xcode/id497799835
- **Apple Developer:** https://developer.apple.com
- **TestFlight:** https://testflight.apple.com

---

## Support

**Having issues?**

1. Check this guide's Troubleshooting section
2. Check console logs in Xcode
3. Check Supabase logs in dashboard
4. Review error messages carefully
5. Search for error message online

**Still stuck?**

- Review docs: `/docs/` folder
- Check INTEGRATION_GUIDE.md
- Check CONFIGURATION.md

---

**Document Version:** 1.0
**Last Updated:** November 19, 2024
**Tested With:** Xcode 15.0, iOS 17.0+, macOS Ventura+

Good luck with testing! 🚀
