// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OnsarjCore", targets: ["OnsarjCore"]),
        .library(name: "LiveActivityModels", targets: ["LiveActivityModels"]),
        .library(name: "Localization", targets: ["Localization"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Storage", targets: ["Storage"]),
        .library(name: "LocationKit", targets: ["LocationKit"]),
        .library(name: "Telemetry", targets: ["Telemetry"]),
        .library(name: "PushNotifications", targets: ["PushNotifications"]),
    ],
    targets: [
        .target(name: "OnsarjCore"),
        .target(name: "LiveActivityModels"),
        .target(name: "Localization"),
        .target(name: "DesignSystem", dependencies: ["OnsarjCore"]),
        .target(name: "Networking", dependencies: ["OnsarjCore", "Telemetry"]),
        .target(name: "Storage", dependencies: ["OnsarjCore"]),
        .target(name: "LocationKit", dependencies: ["OnsarjCore"]),
        .target(name: "Telemetry", dependencies: ["OnsarjCore"]),
        .target(name: "PushNotifications", dependencies: ["OnsarjCore"]),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "OnsarjCore",
                "LiveActivityModels",
                "Localization",
                "DesignSystem",
                "Networking",
                "Storage",
                "LocationKit",
                "Telemetry",
                "PushNotifications",
            ]
        ),
    ]
)
