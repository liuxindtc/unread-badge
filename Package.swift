// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnreadBadge",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UnreadBadgeCore", targets: ["UnreadBadgeCore"]),
        .executable(name: "UnreadBadge", targets: ["UnreadBadge"]),
    ],
    targets: [
        .target(name: "UnreadBadgeCore"),
        .executableTarget(name: "UnreadBadge", dependencies: ["UnreadBadgeCore"]),
        .testTarget(name: "UnreadBadgeCoreTests", dependencies: ["UnreadBadgeCore"]),
    ]
)
