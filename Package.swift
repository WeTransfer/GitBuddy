// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// We're hiding dev, test, and danger dependencies with // dev to make sure they're not fetched by users of this package.
import PackageDescription

let package = Package(
    name: "ChangelogProducer",
    platforms: [
        .macOS(.v10_15)
        ],
    products: [
        // dev .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"]),
        .executable(name: "ChangelogProducer", targets: ["ChangelogProducer"])
    ],
    dependencies: [
        // dev .package(url: "https://github.com/danger/swift", from: "3.0.0"),
        // dev .package(path: "Submodules/WeTransfer-iOS-CI/Danger-Swift"),
        // dev .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.0.0"),
        .package(url: "https://github.com/nerdishbynature/octokit.swift", from: "0.9.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0")
    ],
    targets: [
        // dev .testTarget(name: "ChangelogProducerTests", dependencies: ["ChangelogProducer", "Mocker"]),
        // dev .target(name: "DangerDependencies", dependencies: ["Danger", "WeTransferPRLinter"], path: "Submodules/WeTransfer-iOS-CI/Danger-Swift", sources: ["DangerFakeSource.swift"]),
        .target(name: "ChangelogProducer", dependencies: ["ChangelogProducerCore"]),
        .target(name: "ChangelogProducerCore", dependencies: ["OctoKit", "SPMUtility"])
    ]
)
