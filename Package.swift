// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "GitBuddy",
    platforms: [
        .macOS(.v10_15)
        ],
    products: [
        .executable(name: "GitBuddy", targets: ["GitBuddy"])
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "2.1.0")),
//        .package(path: "../../Forks/octokit.swift"),
//        .package(url: "https://github.com/nerdishbynature/octokit.swift", .upToNextMajor(from: "0.10.1")),
        .package(url: "https://github.com/AvdLee/octokit.swift", .branch("master")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .executableTarget(name: "GitBuddy", dependencies: ["GitBuddyCore"]),
        .target(name: "GitBuddyCore", dependencies: [
            .product(name: "OctoKit", package: "octokit.swift"),
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
        .testTarget(name: "GitBuddyTests", dependencies: ["GitBuddy", "Mocker"])
    ]
)
