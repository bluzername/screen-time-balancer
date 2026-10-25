# Screen Time Balancer

Parental control system built around an earn-to-play rule: children unlock recreational apps by first spending time in educational ones. Parents set the rules and watch progress from their own device; a Supabase backend keeps the family in sync.

## What is in this repository

| Directory | What it is | Status |
|-----------|-----------|--------|
| `backend/` | Supabase project: schema and row-level-security migrations, a `daily-reset` edge function, `config.toml` | Migrations apply with `supabase db push` |
| `ios-parent/` | SwiftUI parent app (`ScreenTimeParent.xcodeproj`): auth, family management, app categorisation, rules, usage reports, polling sync | Builds the pure core as a Swift package; full app has known compile errors against current supabase-swift (see below) |
| `ios-child/` | SwiftUI child app (`ScreenTimeChild.xcodeproj`) plus `ScreenTimeMonitor` DeviceActivity extension: educational time tracking and enforcement via FamilyControls | Needs a physical device and the Family Controls entitlement |
| `android-parent/`, `android-child/` | Kotlin / Jetpack Compose ports with Hilt, a foreground monitoring service, accessibility-based enforcement and a blocking overlay | Gradle projects; no CI build yet |
| `docs/` | Architecture, API, configuration, deployment, integration and Xcode setup guides | |

## Quick start

### 1. Backend

```bash
npm install -g supabase
cd backend
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Copy the project URL and anon key from the Supabase dashboard (Project Settings > API). Details in `backend/docs/SETUP.md`.

### 2. iOS apps

Each app reads its Supabase settings from an untracked `Config.swift`:

```bash
cp ios-parent/ScreenTimeParent/App/Config-Template.swift ios-parent/ScreenTimeParent/App/Config.swift
cp ios-child/ScreenTimeChild/App/Config-Template.swift  ios-child/ScreenTimeChild/App/Config.swift
```

Edit the two copies (or set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the scheme's environment), open the `.xcodeproj` in Xcode 15+, pick your team and run. The child app only works on a real device (iOS 17+) with the Family Controls capability; see `ios-child/DEVICE_ACTIVITY_SETUP.md`.

### 3. Android apps

Open `android-parent` or `android-child` in Android Studio (compileSdk 34, minSdk 29) and supply the Supabase URL and key where `SupabaseClient.kt` expects them.

## Building and testing without Xcode

The parent app's models and validators are platform independent and packaged as `ScreenTimeCore` (`ios-parent/Package.swift`):

```bash
cd ios-parent
swift build
swift test      # XCTest suite for the validators
```

CI runs exactly this on macOS, plus a type-check of both `Config-Template.swift` files.

## Known issues

- `ScreenTimeParent.xcodeproj` resolves `supabase-swift` 2.x at its latest version, and `Shared/Networking/{AuthRepository,SupabaseClient,RealtimeManager}.swift` were written against an older Realtime API (`RealtimeChannel.postgresChange`, `RealtimeClient.removeChannel`). `xcodebuild` currently fails with 16 errors in those three files. Realtime is disabled by default in favour of polling (`Config.enablePolling`), so the fix is either to pin the package to the 2.x minor it was written for or to port `RealtimeManager` to `RealtimeChannelV2`.
- Neither Xcode project has a unit test target; the Swift package above is the tested surface.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [API](docs/API.md)
- [Configuration](docs/CONFIGURATION.md)
- [Getting started](docs/GETTING_STARTED.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Integration guide](docs/INTEGRATION_GUIDE.md)
- [Xcode setup and testing](docs/XCODE_SETUP_AND_TESTING_GUIDE.md)
- [Backend setup](backend/docs/SETUP.md)

## License

Copyright 2024. All rights reserved.
