// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VigClean",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VigClean", targets: ["VigClean"])
    ],
    targets: [
        .executableTarget(
            name: "VigClean",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
