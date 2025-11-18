# Device Activity Monitor Extension Setup Guide

Complete guide for setting up the Device Activity Monitor extension in Xcode for real-time app tracking and enforcement.

## Overview

The Device Activity Monitor extension is a separate app extension target that runs in its own process and monitors app usage in real-time using Apple's Screen Time API. This is required for production-level app blocking and usage tracking.

## Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Apple Developer account (paid)
- Family Controls capability approval from Apple

---

## Step 1: Add App Extension Target

### 1.1 Create New Target

1. Open `ScreenTimeChild.xcodeproj` in Xcode
2. File → New → Target...
3. Select "Device Activity Monitor Extension"
4. Click "Next"

### 1.2 Configure Target

```
Product Name: ScreenTimeMonitor
Organization Identifier: com.yourcompany
Bundle Identifier: com.yourcompany.screentimechild.monitor
Language: Swift
Project: ScreenTimeChild
Embed in Application: ScreenTimeChild
```

5. Click "Finish"
6. When prompted "Activate ScreenTimeMonitor scheme?", click "Activate"

---

## Step 2: Add Extension Files

### 2.1 Delete Generated Files

Xcode creates a default `DeviceActivityMonitor.swift` file. Delete it and replace with our files:

1. In Project Navigator, find `ScreenTimeMonitor` folder
2. Delete `DeviceActivityMonitor.swift`
3. Delete generated `Info.plist` if any

### 2.2 Add Our Files

Drag these files into the `ScreenTimeMonitor` folder in Xcode:

```
ScreenTimeMonitor/
├── DeviceActivityMonitorExtension.swift
├── SharedDataManager.swift
└── Info.plist
```

**Important:** When adding files, ensure:
- ✅ "Copy items if needed" is checked
- ✅ Target membership includes "ScreenTimeMonitor"
- ✅ Target membership includes "ScreenTimeChild" for SharedDataManager.swift (shared)

---

## Step 3: Configure App Group

App Groups allow the extension and main app to share data.

### 3.1 Create App Group

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Certificates, IDs & Profiles → Identifiers → App Groups
3. Click "+" to create new App Group
4. Description: "Screen Time Balancer Shared Data"
5. Identifier: `group.com.yourcompany.screentimechild`
6. Click "Continue" and "Register"

### 3.2 Enable App Group in Main App

1. In Xcode, select `ScreenTimeChild` target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "App Groups"
5. Click "+" under App Groups
6. Enter: `group.com.yourcompany.screentimechild`
7. Ensure it's checked ✅

### 3.3 Enable App Group in Extension

1. Select `ScreenTimeMonitor` target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "App Groups"
5. Click "+" under App Groups
6. Enter: `group.com.yourcompany.screentimechild`
7. Ensure it's checked ✅

### 3.4 Update App Group Identifier in Code

Update `SharedDataManager.swift`:

```swift
private let appGroupIdentifier = "group.com.yourcompany.screentimechild"
```

Replace with your actual App Group identifier.

---

## Step 4: Configure Capabilities

### 4.1 Main App Capabilities

For `ScreenTimeChild` target:

1. Signing & Capabilities tab
2. Ensure these capabilities are added:
   - ✅ Family Controls
   - ✅ App Groups (configured above)
   - ✅ Background Modes:
     - ✅ Background fetch
     - ✅ Background processing

### 4.2 Extension Capabilities

For `ScreenTimeMonitor` target:

1. Signing & Capabilities tab
2. Ensure these capabilities are added:
   - ✅ Family Controls
   - ✅ App Groups (configured above)

---

## Step 5: Update Bundle Identifiers

### 5.1 Main App

```
Bundle Identifier: com.yourcompany.screentimechild
```

### 5.2 Extension

```
Bundle Identifier: com.yourcompany.screentimechild.monitor
```

**Important:** Extension bundle ID must be:
- A child of the main app's bundle ID
- Format: `{main-app-bundle-id}.{extension-name}`

---

## Step 6: Configure Entitlements

### 6.1 Request Family Controls Entitlement

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Certificates, IDs & Profiles → Identifiers
3. Select your main app identifier (`com.yourcompany.screentimechild`)
4. Enable "Family Controls" capability
5. Save

6. Select your extension identifier (`com.yourcompany.screentimechild.monitor`)
7. Enable "Family Controls" capability
8. Save

9. In Xcode, refresh profiles:
   - Xcode → Preferences → Accounts
   - Select your team
   - Click "Download Manual Profiles"

### 6.2 Request App Review Approval

**Important:** Family Controls requires App Review approval.

When submitting to App Review, provide:
- Clear explanation of how you use Screen Time API
- Screenshots showing parental consent flow
- Demonstration of educational time tracking
- Explanation of app blocking mechanism

---

## Step 7: Add Device Activity Schedule in Main App

The scheduler files are already created. Verify they're in your project:

```
ScreenTimeChild/Features/Enforcement/
├── EnforcementEngine.swift (updated)
└── DeviceActivityScheduler.swift (new)
```

These files handle scheduling device activity monitoring.

---

## Step 8: Test the Extension

### 8.1 Build and Run

1. Select `ScreenTimeChild` scheme
2. Select a physical iOS device (not simulator)
3. Click Run (⌘R)

**Important:** Device Activity Monitor **only works on physical devices**, not simulators.

### 8.2 Verify Extension is Running

Add logging to verify:

```swift
// In DeviceActivityMonitorExtension.swift
override func intervalDidStart(for activity: DeviceActivityName) {
    print("📱 Extension: Activity started - \(activity)")
    super.intervalDidStart(for: activity)
}
```

View logs in Xcode Console when you open/close apps.

### 8.3 Debug the Extension

To debug the extension:

1. Run the main app
2. In Xcode: Debug → Attach to Process → ScreenTimeMonitor
3. Set breakpoints in extension code
4. Open/close apps to trigger breakpoints

---

## Step 9: Configure App Selection (Production)

For production, implement proper app selection:

### 9.1 Add FamilyActivityPicker to UI

In `ChildDashboardView.swift` or settings:

```swift
import FamilyControls

struct AppSelectionView: View {
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        VStack {
            FamilyActivityPicker(selection: $selection)

            Button("Save Selection") {
                // Save the selected apps
                saveSelectedApps(selection)
            }
        }
    }

    private func saveSelectedApps(_ selection: FamilyActivitySelection) {
        // Get tokens for selected apps
        let appTokens = selection.applicationTokens
        let categoryTokens = selection.categoryTokens

        // Store for use in DeviceActivityScheduler
        // Use these tokens in DeviceActivityEvent
    }
}
```

### 9.2 Use Application Tokens

Update `DeviceActivityScheduler.swift` to use real tokens:

```swift
let event = DeviceActivityEvent(
    applications: appTokens,  // From FamilyActivitySelection
    threshold: DateComponents(minute: requiredMinutes)
)
```

---

## Step 10: Background Sync Setup

### 10.1 Register Background Task

In `Info.plist` for main app:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourcompany.screentimechild.sync</string>
</array>
```

### 10.2 Schedule Background Task

In `App/ScreenTimeChildApp.swift`:

```swift
import BackgroundTasks

func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.yourcompany.screentimechild.sync",
        using: nil
    ) { task in
        self.handleBackgroundSync(task: task as! BGAppRefreshTask)
    }

    return true
}

func handleBackgroundSync(task: BGAppRefreshTask) {
    let syncManager = BackgroundSyncManager()

    Task {
        await syncManager.syncPendingSessions()
        task.setTaskCompleted(success: true)
    }

    // Schedule next sync
    scheduleNextSync()
}
```

---

## Troubleshooting

### Extension Not Running

**Problem:** Extension code not being called

**Solutions:**
1. Verify extension is embedded in main app:
   - Main App target → General → Frameworks, Libraries, and Embedded Content
   - Should see `ScreenTimeMonitor.appex`

2. Check signing:
   - Both targets should use same Team
   - Both should have proper provisioning profiles

3. Check capabilities:
   - Family Controls enabled on both targets
   - App Groups configured correctly

### App Groups Not Working

**Problem:** Can't share data between app and extension

**Solutions:**
1. Verify App Group identifier is identical in both targets
2. Check App Group is registered in Developer Portal
3. Ensure App Group is enabled in both targets' capabilities
4. Try cleaning build folder (⌘⇧K) and rebuilding

### Authorization Issues

**Problem:** `AuthorizationCenter.shared.requestAuthorization()` fails

**Solutions:**
1. Request authorization before scheduling activities:
   ```swift
   try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
   ```

2. Check Screen Time is enabled on device:
   - Settings → Screen Time → Turn On Screen Time

3. Verify you're testing on physical device (not simulator)

### Monitoring Not Starting

**Problem:** `DeviceActivityCenter.startMonitoring()` fails

**Solutions:**
1. Ensure valid `DateComponents` for schedule
2. Check you have proper authorization status
3. Verify applications and categories in events are valid
4. Try restarting device

### Extension Crashes

**Problem:** Extension crashes when monitoring starts

**Solutions:**
1. Check for force unwrapping (`!`) in extension code
2. Verify shared data exists before accessing
3. Add proper error handling
4. Check Console logs for crash details

---

## Production Checklist

Before submitting to App Store:

- [ ] Extension target added and configured
- [ ] App Group created and enabled on both targets
- [ ] Family Controls capability added to both targets
- [ ] Bundle identifiers correctly configured
- [ ] FamilyActivityPicker implemented for app selection
- [ ] Real application tokens used (not bundle IDs)
- [ ] Background sync configured
- [ ] Parental consent flow implemented
- [ ] Privacy policy updated
- [ ] App Review notes prepared explaining Screen Time API usage
- [ ] Tested on multiple physical devices
- [ ] Verified app blocking works correctly
- [ ] Confirmed usage tracking is accurate

---

## Testing Workflow

1. **Development Testing:**
   ```
   1. Run app on device
   2. Grant Family Controls permission
   3. Configure rules in parent app
   4. Open educational app for required time
   5. Verify recreational apps unlock
   6. Check logs for extension activity
   ```

2. **Integration Testing:**
   ```
   1. Create family and link devices
   2. Set rules in parent app
   3. Verify rules sync to child device
   4. Test app blocking enforcement
   5. Verify usage data syncs to backend
   6. Check reports in parent app
   ```

3. **Beta Testing (TestFlight):**
   ```
   1. Submit both targets to TestFlight
   2. Distribute to beta testers
   3. Collect feedback on enforcement accuracy
   4. Monitor crash reports
   5. Iterate based on feedback
   ```

---

## Performance Considerations

### Extension Performance

- Extension runs in separate process with limited resources
- Keep computations lightweight
- Use shared data for communication
- Minimize file I/O operations
- Batch database operations

### Main App Performance

- Schedule activities once, not repeatedly
- Cache app categories locally
- Sync usage data in batches
- Use background tasks for heavy operations

### Battery Impact

- Device Activity Monitor is designed to be battery-efficient
- Apple handles most optimization
- Minimize custom tracking timers
- Use system-provided events when possible

---

## Resources

- [Apple: Family Controls Documentation](https://developer.apple.com/documentation/familycontrols)
- [Apple: Device Activity Framework](https://developer.apple.com/documentation/deviceactivity)
- [Apple: Screen Time API Sample Code](https://developer.apple.com/documentation/familycontrols/familycontrols_sample_code)
- [WWDC: Meet Screen Time API](https://developer.apple.com/videos/play/wwdc2021/10123/)

---

## Support

For issues with this setup:
1. Check troubleshooting section above
2. Review Apple's documentation
3. Post in Apple Developer Forums
4. Contact Apple Developer Support

---

**Last Updated:** 2024-11-18
**iOS Version:** 17.0+
**Xcode Version:** 15.0+
