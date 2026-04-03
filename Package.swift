// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CleanLockApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/ugurcandede/cleanlock.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "CleanLockApp",
            dependencies: [
                .product(name: "CleanLockCore", package: "cleanlock")
            ],
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
