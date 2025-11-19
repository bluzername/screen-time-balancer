# Integration Guide - Week 1-3 Improvements

This guide provides step-by-step instructions for integrating all the new components created during the Week 1-3 improvement sprint.

## Status

✅ **Completed:**
- All new files created (18 files)
- Config.swift updated with environment variable support (both apps)
- Authentication views updated with validation
- All code committed and pushed

⚠️ **Needs Integration:**
- Replace EnforcementEngine with EnforcementEngineV2
- Integrate RealtimeManager into Parent app ViewModels
- Add ErrorHandler throughout codebase
- Add RetryManager to network operations

---

## 1. Replace EnforcementEngine with V2

### File: `ios-child/ScreenTimeChild/App/ScreenTimeChildApp.swift`

**Current:**
```swift
@StateObject private var enforcementEngine = EnforcementEngine()
```

**Replace with:**
```swift
@StateObject private var enforcementEngine = EnforcementEngineV2()
```

### File: `ios-child/ScreenTimeChild/Features/Dashboard/ChildDashboardView.swift`

No changes needed - uses `@EnvironmentObject var enforcementEngine` (type agnostic).

### Benefits:
- ✅ Eliminates race conditions
- ✅ Proper concurrency with @MainActor
- ✅ Better error handling
- ✅ Cleaner state management

---

## 2. Integrate AppTokenStorage into EnforcementEngineV2

### File: `ios-child/ScreenTimeChild/Features/Enforcement/EnforcementEngineV2.swift`

The file already uses `AppTokenStorage`:

```swift
private let tokenStorage: AppTokenStorage

init(..., tokenStorage: AppTokenStorage = AppTokenStorage(), ...) {
    self.tokenStorage = tokenStorage
    ...
}

private func lockRecreationalApps() async {
    let recreationalTokens = tokenStorage.getRecreationalTokens()
    store.shield.applications = recreationalTokens
}
```

✅ **Already integrated** - No changes needed.

---

## 3. Integrate RealtimeManager into Parent App

### File: `ios-parent/ScreenTimeParent/Features/Dashboard/MainTabView.swift`

**Add to the view:**

```swift
@StateObject private var realtimeManager = RealtimeManager()
@State private var selectedFamilyId: UUID?

var body: some View {
    TabView {
        // ... existing tabs
    }
    .onAppear {
        setupRealtime()
    }
    .onDisappear {
        Task {
            await realtimeManager.disconnect()
        }
    }
}

private func setupRealtime() {
    // Get family ID from somewhere (e.g., first family)
    guard let familyId = selectedFamilyId else { return }

    Task {
        await realtimeManager.subscribeToFamily(familyId: familyId)
    }

    // Setup callbacks
    realtimeManager.onEarnedTimeUpdate = { [weak self] earnedTime in
        // Refresh UI or update state
        print("Real-time update: \(earnedTime)")
    }
}
```

### File: `ios-parent/ScreenTimeParent/Features/Family/FamilyViewModel.swift`

**Add RealtimeManager:**

```swift
@Published var realtimeConnected = false
private var realtimeManager: RealtimeManager?

func setupRealtime(familyId: UUID) async {
    guard Config.enableRealtime else { return }

    realtimeManager = RealtimeManager()

    await realtimeManager?.subscribeToFamily(familyId: familyId)

    // Handle updates
    realtimeManager?.onEarnedTimeUpdate = { [weak self] earnedTime in
        Task { @MainActor in
            // Update your published properties
            await self?.loadFamilyDetails(familyId: familyId)
        }
    }

    realtimeConnected = true
}

func disconnect() async {
    await realtimeManager?.disconnect()
    realtimeConnected = false
}
```

**Call in view:**

```swift
.onAppear {
    viewModel.loadFamilies()

    if let familyId = viewModel.families.first?.id {
        Task {
            await viewModel.setupRealtime(familyId: familyId)
        }
    }
}
.onDisappear {
    Task {
        await viewModel.disconnect()
    }
}
```

---

## 4. Add ErrorHandler to Repositories

### Create a shared instance:

**File: `ios-parent/ScreenTimeParent/Shared/Utilities/ErrorHandler+Shared.swift`**

```swift
import Foundation

extension ErrorHandler {
    static let shared = ErrorHandler()
}
```

### Update repositories to use ErrorHandler:

**File: `ios-parent/ScreenTimeParent/Shared/Networking/AuthRepository.swift`**

**Before:**
```swift
func signIn(email: String, password: String) async throws -> UserProfile {
    let response = try await client.auth.signIn(...)
    return profile
}
```

**After:**
```swift
func signIn(email: String, password: String) async throws -> UserProfile {
    do {
        let response = try await client.auth.signIn(...)
        return profile
    } catch {
        ErrorHandler.shared.handle(error, context: "AuthRepository.signIn")
        throw error
    }
}
```

**Apply to all repository methods.**

### Update ViewModels:

**Example: `ios-parent/ScreenTimeParent/Features/Authentication/AuthenticationViewModel.swift`**

```swift
@StateObject private var errorHandler = ErrorHandler.shared

func signIn(email: String, password: String) {
    Task {
        do {
            let user = try await authRepository.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorHandler.handle(error, context: "SignIn")
        }
    }
}
```

**In view:**
```swift
.errorAlert($errorHandler.currentError)
```

---

## 5. Add RetryManager to Network Operations

### Create shared RetryManager:

**File: `ios-parent/ScreenTimeParent/Shared/Utilities/RetryManager+Shared.swift`**

```swift
import Foundation

extension RetryManager {
    static let shared = RetryManager(maxAttempts: 3, baseDelay: 1.0)
}
```

### Update repositories for network calls:

**File: `ios-parent/ScreenTimeParent/Shared/Networking/FamilyRepository.swift`**

**Before:**
```swift
func getUserFamilies() async throws -> [FamilyOverview] {
    return try await client.database
        .from("family_overview")
        .select()
        .execute()
        .value
}
```

**After:**
```swift
func getUserFamilies() async throws -> [FamilyOverview] {
    return try await RetryManager.shared.execute(operation: "getUserFamilies") {
        try await client.database
            .from("family_overview")
            .select()
            .execute()
            .value
    }
}
```

**Apply to all network methods** (create, update, delete, fetch operations).

---

## 6. Update App Initialization

### File: `ios-parent/ScreenTimeParent/App/ScreenTimeParentApp.swift`

**Add configuration logging:**

```swift
init() {
    // Print configuration
    Config.printConfiguration()

    // Validate configuration
    let validation = Config.validateConfiguration()
    if !validation.isValid {
        print("⚠️ Configuration errors:")
        validation.errors.forEach { print("  - \($0)") }
    }
}
```

### File: `ios-child/ScreenTimeChild/App/ScreenTimeChildApp.swift`

Same as above - add configuration logging.

---

## 7. Testing Checklist

### Unit Tests (Create These)

**File: `ios-parent/ScreenTimeParent/Tests/ValidatorsTests.swift`**

```swift
import XCTest
@testable import ScreenTimeParent

final class ValidatorsTests: XCTestCase {

    func testEmailValidation() {
        XCTAssertTrue(EmailValidator.isValid("user@example.com"))
        XCTAssertFalse(EmailValidator.isValid("invalid"))
        XCTAssertFalse(EmailValidator.isValid("@example.com"))
    }

    func testPasswordValidation() {
        let weak = PasswordValidator.validate("short")
        XCTAssertFalse(weak.isValid)

        let strong = PasswordValidator.validate("SecurePass123!")
        XCTAssertTrue(strong.isValid)
    }

    func testInviteCodeValidation() {
        XCTAssertTrue(InviteCodeValidator.isValid("ABC12345"))
        XCTAssertFalse(InviteCodeValidator.isValid("ABC"))
        XCTAssertFalse(InviteCodeValidator.isValid("ABC123456"))
    }
}
```

**Run tests:**
```bash
xcodebuild test -scheme ScreenTimeParent -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Integration Tests

1. **Authentication Flow:**
   - Sign up with weak password → Should show error
   - Sign up with strong password → Should succeed
   - Invalid email → Should show error
   - Rate limiting → Try 6 times → Should block

2. **Join Family Flow:**
   - Invalid invite code → Should show error
   - Valid invite code → Should join and register device
   - Already a member → Should show error

3. **Realtime Updates:**
   - Parent app open
   - Child completes educational time on device
   - Parent should see update without refresh

4. **Error Handling:**
   - Disconnect internet
   - Try to load families
   - Should show network error with retry option
   - Reconnect internet
   - Retry → Should succeed

5. **Configuration:**
   - Set environment variables
   - Launch app
   - Check console for correct values

---

## 8. Deployment Checklist

### Before Production:

- [ ] Replace all `Config.swift` files with actual credentials
- [ ] Set environment variables in CI/CD
- [ ] Test on physical devices (not just simulator)
- [ ] Run full test suite
- [ ] Check crash analytics integration
- [ ] Verify Rate Limiter works (try 6 failed logins)
- [ ] Test Realtime subscriptions with multiple devices
- [ ] Verify offline mode works (airplane mode)
- [ ] Check memory usage with Instruments
- [ ] Performance test with 1000+ usage sessions

### TestFlight:

- [ ] Upload build to TestFlight
- [ ] Add beta testers
- [ ] Monitor crash reports (2 weeks minimum)
- [ ] Collect feedback on new validation UX
- [ ] Check battery usage (Background Tasks)
- [ ] Verify push notifications work

### App Store:

- [ ] Update App Store description with new features
- [ ] Add screenshots showing validation
- [ ] Privacy policy updated (if needed)
- [ ] Submit for review
- [ ] Monitor first 24 hours after release

---

## 9. Quick Integration Script

For rapid integration, run this in each app directory:

```bash
#!/bin/bash
# integrate.sh - Quick integration helper

echo "🔧 Integrating Week 1-3 improvements..."

# 1. Replace old EnforcementEngine
echo "Replacing EnforcementEngine with V2..."
find . -name "*.swift" -type f -exec sed -i '' 's/= EnforcementEngine()/= EnforcementEngineV2()/g' {} +

# 2. Add ErrorHandler import
echo "Adding ErrorHandler imports..."
# (Manual step - add import to each repository file)

# 3. Create test files
echo "Creating test file structure..."
mkdir -p Tests
touch Tests/ValidatorsTests.swift
touch Tests/ErrorHandlingTests.swift

echo "✅ Basic integration complete!"
echo "⚠️  Manual steps still required - see INTEGRATION_GUIDE.md"
```

---

## 10. Rollback Plan

If issues occur after integration:

### Quick Rollback:

1. **Revert EnforcementEngineV2:**
   ```swift
   @StateObject private var enforcementEngine = EnforcementEngine()
   ```

2. **Disable Realtime:**
   ```swift
   // In Config.swift
   static let enableRealtime = false
   ```

3. **Remove ErrorHandler:**
   ```swift
   // Comment out ErrorHandler.shared.handle() calls
   ```

4. **Git Revert:**
   ```bash
   git revert HEAD
   git push
   ```

### Feature Flags:

Add to `Config.swift`:

```swift
static let useEnforcementV2 = false  // Switch between versions
static let useRealtimeManager = false  // Toggle realtime
static let useRetryManager = false  // Toggle retry logic
```

Then in code:

```swift
@StateObject private var enforcementEngine = {
    if Config.useEnforcementV2 {
        return EnforcementEngineV2()
    } else {
        return EnforcementEngine()
    }
}()
```

---

## 11. Performance Benchmarks

Track these metrics before/after integration:

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| App Launch Time | ? | ? | < 2s |
| Sign In Time | ? | ? | < 1s |
| Load Families | ? | ? | < 500ms |
| Realtime Latency | N/A | ? | < 2s |
| Memory Usage | ? | ? | < 100MB |
| Battery Drain (24h) | ? | ? | < 5% |

---

## 12. Common Issues & Solutions

### Issue: "Supabase URL not configured"

**Solution:**
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-key"
open ScreenTimeParent.xcodeproj
```

### Issue: Realtime not connecting

**Solution:**
- Check Supabase Realtime is enabled in dashboard
- Verify RLS policies allow subscriptions
- Check network connection
- Look for WebSocket errors in console

### Issue: Rate Limiter not working

**Solution:**
- Rate Limiter is in-memory only
- Resets on app restart
- For persistent rate limiting, use backend

### Issue: EnforcementEngineV2 compile errors

**Solution:**
- Make sure AppTokenStorage.swift is added to target
- Verify FamilyControls framework is linked
- Check minimum iOS version (17.0+)

---

## 13. Next Steps After Integration

### Week 4 Tasks:

1. **Add Test Suite** (Critical)
   - Unit tests for all Validators
   - Integration tests for repositories
   - UI tests for critical flows

2. **Performance Optimization**
   - Profile with Instruments
   - Optimize RealtimeManager reconnection
   - Cache frequently accessed data

3. **User Experience**
   - Add loading indicators for realtime connection
   - Improve error messages based on feedback
   - Add success animations for validations

4. **Documentation**
   - Record video tutorials
   - Create troubleshooting FAQ
   - Document all environment variables

### Week 5-6: Beta Testing

1. TestFlight distribution
2. Crash monitoring
3. User feedback collection
4. Bug fixes
5. Performance tuning

---

## Conclusion

This integration guide provides everything needed to wire up all the Week 1-3 improvements. Follow the steps in order, test thoroughly, and use the rollback plan if issues arise.

**Estimated Time:**
- Basic integration: 4-6 hours
- Full testing: 8-10 hours
- Bug fixes: 4-6 hours
- **Total: 2-3 days**

**Priority Order:**
1. Config updates (done ✅)
2. EnforcementEngineV2 replacement
3. Error handling integration
4. Retry logic
5. Realtime integration
6. Testing

Good luck! 🚀

---

*Document Version: 1.0*
*Last Updated: November 19, 2024*
*Status: Ready for Integration*
