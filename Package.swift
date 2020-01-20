// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChangelogProducer",
    platforms: [
        .macOS(.v10_15)
        ],
    products: [
        .executable(name: "ChangelogProducer", targets: ["ChangelogProducer"]),
        .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"]) // dev
    ],
    dependencies: [
        .package(url: "https://github.com/danger/swift", from: "3.0.0"), // dev
        .package(path: "Submodules/WeTransfer-iOS-CI/Danger-Swift"), // dev
        .package(url: "https://github.com/nerdishbynature/octokit.swift", from: "0.9.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "ChangelogProducer",
                dependencies: ["ChangelogProducerCore"]),
        .target(name: "ChangelogProducerCore",
                dependencies: ["OctoKit", "SPMUtility"]),
        .testTarget(name: "ChangelogProducerTests",
                    dependencies: ["ChangelogProducer", "Mocker"]),
        .target(name: "DangerDependencies", dependencies: ["Danger", "WeTransferPRLinter"], path: "Submodules/WeTransfer-iOS-CI/Danger-Swift", sources: ["DangerFakeSource.swift"]) // dev
    ]
)
