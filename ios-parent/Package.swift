// swift-tools-version: 5.9
// ScreenTimeCore: the platform-independent part of the parent app (models and
// validators), packaged so it can be built and unit tested with `swift build`
// and `swift test` on macOS or Linux without Xcode, a device, or Supabase.
//
// The app itself is built from ScreenTimeParent.xcodeproj, which compiles the
// full ScreenTimeParent folder (SwiftUI, FamilyControls, Supabase) for iOS.
import PackageDescription

let package = Package(
    name: "ScreenTimeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ScreenTimeCore", targets: ["ScreenTimeCore"]),
    ],
    targets: [
        .target(
            name: "ScreenTimeCore",
            path: "ScreenTimeParent/Shared",
            exclude: [
                "Networking",
                "Utilities/ErrorHandling.swift",
                "Utilities/ErrorHandler+Shared.swift",
                "Utilities/RetryManager+Shared.swift"
            ],
            sources: ["Models", "Utilities/Validators.swift"]
        ),
        .testTarget(
            name: "ScreenTimeCoreTests",
            dependencies: ["ScreenTimeCore"],
            path: "Tests/ScreenTimeCoreTests"
        ),
    ]
)
