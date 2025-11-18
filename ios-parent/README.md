# Screen Time Parent App

The parent app for Screen Time Balancer - monitor and manage your children's screen time with an educational-first approach.

## Features

- 👨‍👩‍👧‍👦 Family management and child device linking
- 📊 Real-time usage monitoring dashboard
- 📱 App categorization (educational vs recreational)
- ⚙️ Flexible screen time rules and schedules
- 📈 Weekly usage reports and analytics
- 🔒 Remote device control (lock/unlock)
- 🔄 Real-time sync with child devices

## Requirements

- iOS 17.0+ / iPadOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Active internet connection
- Supabase account

## Installation

### 1. Install Dependencies

Dependencies are managed via Swift Package Manager:

- [supabase-swift](https://github.com/supabase/supabase-swift)

Xcode will automatically resolve dependencies when you open the project.

### 2. Configure Supabase

Update `App/Config.swift`:

```swift
enum Config {
    static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = "YOUR_ANON_KEY"
}
```

Get credentials from your Supabase Dashboard → Settings → API.

### 3. Configure Signing

1. Open `ScreenTimeParent.xcodeproj`
2. Select target "ScreenTimeParent"
3. Signing & Capabilities tab
4. Select your Team
5. Update Bundle Identifier: `com.yourcompany.screentimeparent`

### 4. Build and Run

- Select target device (iPhone/iPad)
- Press ⌘R or click Run button
- App will launch on selected device

## Project Structure

```
ScreenTimeParent/
├── App/                          # App lifecycle and configuration
│   ├── ScreenTimeParentApp.swift # Main app entry point
│   └── Config.swift              # Configuration and constants
├── Features/                     # Feature modules
│   ├── Authentication/           # Login and signup
│   ├── Family/                   # Family management
│   ├── Dashboard/                # Usage monitoring
│   ├── AppCategorization/        # App categorization
│   ├── Rules/                    # Screen time rules
│   └── Settings/                 # App settings
├── Shared/                       # Shared code
│   ├── Models/                   # Data models
│   ├── Networking/               # API clients and repositories
│   ├── Utilities/                # Helper functions
│   └── Components/               # Reusable UI components
├── Resources/                    # Assets and resources
│   ├── Assets.xcassets/         # Images and icons
│   └── Info.plist               # App configuration
└── Tests/                        # Unit and UI tests
```

## Architecture

The app follows MVVM (Model-View-ViewModel) with Clean Architecture principles:

- **Presentation Layer:** SwiftUI views and ViewModels
- **Domain Layer:** Business logic and use cases
- **Data Layer:** Repository pattern and API clients

### Key Components

**Repositories:**
- `AuthRepository`: User authentication
- `FamilyRepository`: Family and member management
- `RulesRepository`: Screen time rules
- `AppsRepository`: App categorization
- `UsageRepository`: Usage tracking and reports

**ViewModels:**
- `AuthenticationViewModel`: Login/signup logic
- `DashboardViewModel`: Usage monitoring
- `FamilyViewModel`: Family management
- `RulesViewModel`: Rules configuration

## Usage

### Creating a Family

```swift
// In FamilyViewModel
func createFamily(name: String) async {
    let family = try await familyRepository.createFamily(
        name: name,
        createdBy: currentUserId
    )
    // Family created with auto-generated invite code
}
```

### Monitoring Child Usage

```swift
// In DashboardViewModel
func loadChildStatus(childId: UUID) async {
    let status = try await usageRepository.getEnforcementStatus(
        childId: childId
    )
    // Display progress and earned time
}
```

### Creating Rules

```swift
// In RulesViewModel
func createRule() async {
    let request = CreateRuleRequest(
        familyId: familyId,
        childId: childId,
        name: "School Days",
        requiredEducationalMinutes: 30,
        maxRecreationalMinutes: 90
    )
    try await rulesRepository.createRule(request)
}
```

## Configuration Options

### App Constants

Modify in `App/Config.swift`:

```swift
enum Config {
    // Supabase
    static let supabaseURL: URL
    static let supabaseAnonKey: String

    // Sync
    static let syncIntervalSeconds: TimeInterval = 300
    static let usageReportDays = 7

    // Defaults
    static let defaultRequiredEducationalMinutes = 30
    static let defaultMaxRecreationalMinutes = 120
}
```

### Feature Flags

```swift
enum Config {
    static let enableBiometricAuth = true
    static let enableRealtime = true
    static let enableOfflineMode = true
}
```

## Testing

### Run Unit Tests

```bash
# Command line
xcodebuild test -scheme ScreenTimeParent \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: ⌘U
```

### Test Coverage

- Authentication flows
- Family management
- Rules CRUD operations
- Usage tracking calculations
- API integration

## Building for Release

### 1. Update Version

In Xcode:
- General tab → Identity
- Version: 1.0
- Build: 1 (increment for each release)

### 2. Archive

```bash
Product → Archive
```

### 3. Upload to App Store Connect

```bash
Window → Organizer → Upload to App Store Connect
```

See [DEPLOYMENT.md](../docs/DEPLOYMENT.md) for complete guide.

## Troubleshooting

### Common Issues

**App crashes on launch:**
- Verify Supabase URL and API key in Config.swift
- Check network connectivity
- Review console logs (⌘⇧C)

**Authentication fails:**
- Verify Supabase project is active
- Check email/password requirements
- Review error messages in logs

**Real-time updates not working:**
- Verify Supabase Realtime is enabled
- Check RLS policies allow subscriptions
- Ensure device has stable internet connection

### Debug Mode

Enable verbose logging:

```swift
// In App/Config.swift
enum Config {
    static let debugMode = true
    static let verboseLogging = true
}
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

Copyright © 2024. All rights reserved.

## Support

- Documentation: [/docs](../docs/)
- Issues: [GitHub Issues](https://github.com/yourusername/screen-time-balancer/issues)
- Email: support@yourcompany.com

## Credits

Built with:
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Supabase](https://supabase.com)
- [Swift Package Manager](https://swift.org/package-manager/)
