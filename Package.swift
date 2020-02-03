// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// We're hiding dev, test, and danger dependencies with // dev to make sure they're not fetched by users of this package.
import PackageDescription

let package = Package(
    name: "GitBuddy",
    platforms: [
        .macOS(.v10_15)
        ],
    products: [
        // dev .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"]),
        .executable(name: "GitBuddy", targets: ["GitBuddy"])
    ],
    dependencies: [
        // dev .package(url: "https://github.com/danger/swift", from: "3.0.0"),
        // dev .package(path: "Submodules/WeTransfer-iOS-CI/Danger-Swift"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.0.0"),
        .package(url: "https://github.com/nerdishbynature/octokit.swift", from: "0.9.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0")
    ],
    targets: [
        .testTarget(name: "GitBuddyTests", dependencies: ["GitBuddy", "Mocker"]),
        // dev .target(name: "DangerDependencies", dependencies: ["Danger", "WeTransferPRLinter"], path: "Submodules/WeTransfer-iOS-CI/Danger-Swift", sources: ["DangerFakeSource.swift"]),
        .target(name: "GitBuddy", dependencies: ["GitBuddyCore"]),
        .target(name: "GitBuddyCore", dependencies: ["OctoKit", "SPMUtility"])
    ]
)
