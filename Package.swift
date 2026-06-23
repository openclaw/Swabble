// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swabble",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "Swabble", targets: ["Swabble"]),
        .executable(name: "swabble", targets: ["SwabbleCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/Commander.git", from: "0.2.2"),
    ],
    targets: [
        .target(
            name: "Swabble",
            path: "Sources/SwabbleCore",
            swiftSettings: []),
        .executableTarget(
            name: "SwabbleCLI",
            dependencies: [
                "Swabble",
                .product(name: "Commander", package: "Commander"),
            ],
            path: "Sources/swabble"),
        .testTarget(
            name: "swabbleTests",
            dependencies: ["Swabble"]),
    ],
    swiftLanguageModes: [.v6]
)
