// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BlueScreenOfDeath",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "BlueScreenOfDeath",
            path: "Sources/BlueScreenOfDeath",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "BlueScreenOfDeathTests",
            dependencies: ["BlueScreenOfDeath"],
            path: "Tests/BlueScreenOfDeathTests"
        )
    ]
)
