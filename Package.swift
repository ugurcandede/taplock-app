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
        .target(
            name: "TapLockAppLib",
            dependencies: [
                .product(name: "TapLockCore", package: "taplock")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "TapLockApp",
            dependencies: [
                "TapLockAppLib",
                .product(name: "TapLockCore", package: "taplock")
            ],
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "TapLockAppTests",
            dependencies: [
                "TapLockAppLib",
                .product(name: "TapLockCore", package: "taplock")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
