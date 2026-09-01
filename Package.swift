// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VigClean",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VigClean", targets: ["VigClean"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6")
    ],
    targets: [
        .executableTarget(
            name: "VigClean",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "VigCleanTests",
            dependencies: ["VigClean"]
        )
    ]
)
