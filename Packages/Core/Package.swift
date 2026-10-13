// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Core",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
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
        .library(name: "PhoneNumbers", targets: ["PhoneNumbers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/PhoneNumberKit/PhoneNumberKit", .upToNextMinor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "OnsarjCore"),
        .target(name: "LiveActivityModels"),
        .target(name: "Localization", resources: [.process("Resources")]),
        .target(name: "DesignSystem", dependencies: ["OnsarjCore"], resources: [.process("Resources")]),
        .target(name: "Networking", dependencies: ["OnsarjCore", "Telemetry"]),
        .target(name: "Storage", dependencies: ["OnsarjCore"]),
        .target(name: "LocationKit", dependencies: ["OnsarjCore"]),
        .target(name: "Telemetry", dependencies: ["OnsarjCore"]),
        .target(name: "PushNotifications", dependencies: ["OnsarjCore"]),
        .target(
            name: "PhoneNumbers",
            dependencies: [.product(name: "PhoneNumberKit", package: "PhoneNumberKit")]
        ),
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
        .testTarget(name: "PhoneNumbersTests", dependencies: ["PhoneNumbers"]),
    ]
)
