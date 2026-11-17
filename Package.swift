// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sidekick",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "SidekickCore"),
        .executableTarget(name: "Sidekick", dependencies: ["SidekickCore"]),
        .testTarget(name: "SidekickCoreTests", dependencies: ["SidekickCore"]),
    ]
)
