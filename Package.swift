// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TapLockApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "deps/taplock")
    ],
    targets: [
        .executableTarget(
            name: "TapLockApp",
            dependencies: [
                .product(name: "TapLockCore", package: "taplock")
            ],
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
