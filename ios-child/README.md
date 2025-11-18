# Screen Time Child App

The child app for Screen Time Balancer - earn recreational screen time by using educational apps first.

## Features

- ⏱️ Real-time educational progress tracking
- 🎯 Clear goals and achievement system
- 🔒 Automatic app enforcement based on rules
- 📊 Personal usage dashboard
- 🎨 Age-appropriate, encouraging interface
- 📴 Offline mode support
- 🔄 Background sync with parent's rules

## Requirements

- iOS 17.0+ / iPadOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- **Physical device** (Screen Time API not available on simulator)
- **Apple Developer Account** (for Family Controls entitlement)
- Active internet connection
- Supabase account

## Installation

### 1. Install Dependencies

Dependencies are managed via Swift Package Manager:

- [supabase-swift](https://github.com/supabase/supabase-swift)
- FamilyControls (Apple framework)

### 2. Configure Supabase

Update `App/Config.swift`:

```swift
enum Config {
    static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = "YOUR_ANON_KEY"
}
```

### 3. Configure Family Controls

**Important:** Screen Time API requires special setup.

1. **Apple Developer Portal:**
   - Certificates, IDs & Profiles → Identifiers
   - Select your app ID
   - Enable "Family Controls" capability
   - Save changes

2. **Xcode Project:**
   - Select target "ScreenTimeChild"
   - Signing & Capabilities
   - + Capability → "Family Controls"
   - Select your Team
   - Update Bundle Identifier: `com.yourcompany.screentimechild`

3. **Request Authorization:**
   - App requests authorization on first launch
   - User must approve Screen Time access

### 4. Build and Run

- **Must use physical device** (not simulator)
- Select connected iPhone/iPad
- Press ⌘R or click Run
- Approve Screen Time permission when prompted

## Project Structure

```
ScreenTimeChild/
├── App/                         # App lifecycle
│   ├── ScreenTimeChildApp.swift # Main entry point
│   └── Config.swift             # Configuration
├── Features/
│   ├── Authentication/          # Child login
│   ├── Dashboard/               # Progress tracking
│   └── Enforcement/             # App blocking logic
│       └── EnforcementEngine.swift  # Core enforcement
├── Shared/
│   ├── Models/                  # Shared data models
│   ├── Networking/              # API clients
│   └── Utilities/               # Helpers
├── Resources/
│   ├── Assets.xcassets/        # Images and icons
│   └── Info.plist              # App configuration
└── Tests/                       # Unit tests
```

## Architecture

### Enforcement Engine

The core of the child app is the `EnforcementEngine` class:

```swift
@MainActor
class EnforcementEngine: ObservableObject {
    // Current rule and earned time
    @Published var currentRule: ScreenTimeRule?
    @Published var earnedTime: EarnedTime?
    @Published var isRecreationalAllowed = false

    // Enforcement logic
    func updateEnforcement() async
    func lockRecreationalApps() async
    func unlockRecreationalApps() async

    // Usage tracking
    func startAppSession(bundleId: String, ...) async
    func endAppSession() async

    // Sync with backend
    func syncWithBackend() async
}
```

### How It Works

1. **App Launch:**
   - Request Screen Time authorization
   - Load rules from backend
   - Check today's earned time
   - Apply enforcement

2. **Usage Tracking:**
   - Monitor when educational apps are used
   - Track duration
   - Sync to backend every 5 minutes
   - Update earned time

3. **Enforcement:**
   - Check if educational requirement met
   - If yes: Unlock recreational apps
   - If no: Keep recreational apps locked
   - Update status in real-time

4. **Real-time Sync:**
   - Subscribe to rule changes from parent
   - Update enforcement immediately
   - Handle parent commands (lock/unlock)

## Screen Time API Integration

### Authorization

```swift
import FamilyControls

let center = AuthorizationCenter.shared

// Request authorization
try await center.requestAuthorization(for: .individual)

// Check status
let status = center.authorizationStatus
// .notDetermined, .denied, .approved
```

### App Shielding

```swift
import ManagedSettings

let store = ManagedSettingsStore()

// Block apps
store.shield.applications = blockedAppTokens
store.shield.applicationCategories = .all(except: .init())

// Unblock apps
store.shield.applications = nil
store.shield.applicationCategories = nil
```

### Device Activity Monitoring

For production, implement a DeviceActivityMonitor extension:

1. Create new target: File → New → Target → Device Activity Monitor Extension
2. Implement monitoring:

```swift
import DeviceActivity

class MyDeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        // App usage started
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // App usage ended
    }
}
```

## Configuration

### Enforcement Settings

```swift
enum Config {
    // How often to track usage
    static let usageTrackingIntervalSeconds: TimeInterval = 10

    // How often to sync with backend
    static let syncIntervalSeconds: TimeInterval = 300

    // Heartbeat for connection monitoring
    static let heartbeatIntervalSeconds: TimeInterval = 30

    // Enable strict enforcement
    static let strictMode = true
}
```

### Feature Flags

```swift
enum Config {
    static let enableLocalEnforcement = true
    static let enableOfflineMode = true
    static let strictMode = true
}
```

## Usage Example

### Child Signs In

```swift
// In ChildAuthenticationView
func signIn() {
    viewModel.signIn(email: email, password: password)
}

// On success, child sees dashboard with progress
```

### Dashboard Updates

```swift
// Real-time updates in ChildDashboardView
@EnvironmentObject var enforcementEngine: EnforcementEngine

var body: some View {
    if let earned = enforcementEngine.earnedTime {
        ProgressCard(earnedTime: earned, rule: currentRule)
    }

    StatusCard(isRecreationalAllowed: enforcementEngine.isRecreationalAllowed)
}
```

### Background Sync

```swift
// Automatic sync every 5 minutes
private func startPeriodicSync() {
    syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) {
        await self.syncWithBackend()
    }
}
```

## Testing

### Run Tests

```bash
xcodebuild test -scheme ScreenTimeChild \
  -destination 'platform=iOS,name=YOUR_DEVICE_NAME'
```

**Note:** Screen Time API tests require physical device.

### Manual Testing Checklist

- [ ] App requests Screen Time permission
- [ ] Child can sign in
- [ ] Dashboard shows current progress
- [ ] Educational apps are tracked
- [ ] Recreational apps locked when requirement not met
- [ ] Recreational apps unlock when requirement met
- [ ] Background sync works
- [ ] Offline mode caches data
- [ ] Parent commands received and executed

## Building for Release

See parent app README and [DEPLOYMENT.md](../docs/DEPLOYMENT.md).

**Important:** Screen Time API requires App Review approval.

## Troubleshooting

### Screen Time Authorization Fails

**Symptoms:**
- Authorization prompt doesn't appear
- Status remains `.notDetermined`

**Solutions:**
- Ensure running on physical device (not simulator)
- Check Family Controls capability is added
- Verify entitlement in project
- Check device restrictions (Screen Time must be enabled)

### App Blocking Not Working

**Symptoms:**
- Recreational apps not blocked
- Shield doesn't appear

**Solutions:**
- Verify authorization status is `.approved`
- Check that tokens are properly configured
- Ensure ManagedSettings store is updated
- Review device restrictions

### Usage Not Tracking

**Symptoms:**
- Educational time not increasing
- Sessions not synced to backend

**Solutions:**
- Check network connectivity
- Verify Supabase credentials
- Review backend RLS policies
- Check timer is running

### Crashes on Launch

**Symptoms:**
- App crashes immediately
- Console shows errors

**Solutions:**
- Clean build folder (⌘⇧K)
- Delete derived data
- Verify Config.swift settings
- Check Supabase project is active
- Review crash logs in Xcode Organizer

## Limitations

### iOS Screen Time API

The Screen Time API has some limitations:

1. **Real Device Required:**
   - API not available on simulator
   - Testing requires physical device

2. **App Selection:**
   - Apps must be selected via FamilyActivityPicker
   - Cannot programmatically shield arbitrary bundle IDs
   - MVP uses simplified approach

3. **Background Monitoring:**
   - Requires Device Activity Monitor extension
   - Extension runs in separate process
   - Limited communication with main app

4. **Approval Required:**
   - Family Controls entitlement requires App Review
   - Must justify Screen Time API usage
   - Provide clear parental consent flow

### Workarounds for MVP

For MVP testing without full Screen Time API integration:

1. **Simplified Enforcement:**
   - UI shows locked/unlocked status
   - Honor system for now
   - Full enforcement in production

2. **Manual Usage Tracking:**
   - Child manually reports app usage
   - Automatic tracking in production with extension

3. **Mock Data:**
   - Use mock usage data for testing
   - Backend API ready for real data

## Security Considerations

### Anti-Tampering

- Server-authoritative enforcement
- All validation done on backend
- Device time validated against server time
- Checksums for usage data integrity

### Data Privacy

- Minimal data collection
- Usage data encrypted in transit
- COPPA compliant
- Parental consent required

## Production Checklist

- [ ] Device Activity Monitor extension implemented
- [ ] Full Screen Time API integration complete
- [ ] Usage tracking fully automated
- [ ] Offline queue implemented
- [ ] Error handling robust
- [ ] Crash reporting integrated
- [ ] Analytics added
- [ ] Parental consent flow implemented
- [ ] Privacy policy linked
- [ ] App Review submission prepared

## Resources

- [Screen Time API Docs](https://developer.apple.com/documentation/familycontrols)
- [Device Activity Framework](https://developer.apple.com/documentation/deviceactivity)
- [Managed Settings](https://developer.apple.com/documentation/managedsettings)
- [WWDC Videos](https://developer.apple.com/videos/)

## License

Copyright © 2024. All rights reserved.

## Support

- Documentation: [/docs](../docs/)
- Issues: [GitHub Issues](https://github.com/yourusername/screen-time-balancer/issues)
