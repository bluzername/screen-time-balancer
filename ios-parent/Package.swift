// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenTimeParent",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ScreenTimeParent",
            targets: ["ScreenTimeParent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "ScreenTimeParent",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "ScreenTimeParent"
        ),
        .testTarget(
            name: "ScreenTimeParentTests",
            dependencies: ["ScreenTimeParent"],
            path: "ScreenTimeParent/Tests"
        ),
    ]
)
