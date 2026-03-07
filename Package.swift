// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "one-man-squad-os",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [
        // MenuBarExtra Settings workaround
        .package(url: "https://github.com/orchetect/SettingsAccess", from: "2.0.0"),
        // FSEvents wrapper (requires non-sandboxed app)
        .package(url: "https://github.com/eonil/FSEvents", from: "0.3.0"),
        // Markdown parsing (official swift-markdown)
        .package(url: "https://github.com/swiftlang/swift-markdown", branch: "main"),
        // YAML frontmatter (swift-markdown does not support it, issue #73)
        .package(url: "https://github.com/SwiftToolkit/frontmatter", from: "1.0.0"),
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
