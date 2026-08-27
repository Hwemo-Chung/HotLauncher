// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HotLauncher",
    platforms: [.macOS(.v15)],
    // ponytail: CLT SwiftPM does not auto-link toolchain Testing.framework
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "HotLauncher",
            path: "Sources/HotLauncher"
        ),
        .executableTarget(
            name: "HotLauncherApp",
            dependencies: ["HotLauncher"],
            path: "Sources/HotLauncherApp"
        ),
        .testTarget(
            name: "HotLauncherTests",
            dependencies: [
                "HotLauncher",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/HotLauncherTests"
        ),
    ]
)
