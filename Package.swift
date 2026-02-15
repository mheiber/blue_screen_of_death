// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BlueScreenOfDeath",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "BlueScreenOfDeath",
            path: "Sources/BlueScreenOfDeath",
            exclude: ["Info.plist", "BlueScreenOfDeath.entitlements", "Resources"],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
                .process("Localized"),
            ]
        ),
        .testTarget(
            name: "BlueScreenOfDeathTests",
            dependencies: ["BlueScreenOfDeath"],
            path: "Tests/BlueScreenOfDeathTests"
        )
    ]
)
