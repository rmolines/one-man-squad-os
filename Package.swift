// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "one-man-squad-os",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [
        // Markdown parsing (official swift-markdown)
        .package(url: "https://github.com/swiftlang/swift-markdown", branch: "main"),
        // YAML frontmatter (swift-markdown does not support it, issue #73)
        .package(url: "https://github.com/SwiftToolkit/frontmatter", from: "1.0.0"),
        // App-level deps (EonilFSEvents, SettingsAccess) are managed
        // via the Xcode project — not needed in the Core SPM target.
    ],
    targets: [
        // Core — no SwiftUI imports, testable in isolation
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Frontmatter", package: "frontmatter"),
            ],
            path: "Sources/Core"
        ),
        // Tests
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
    ],
    swiftLanguageVersions: [.v6]
)
