// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AuthService", targets: ["AuthService"]),
        .library(name: "VehicleService", targets: ["VehicleService"]),
        .library(name: "StationService", targets: ["StationService"]),
        .library(name: "PlaceService", targets: ["PlaceService"]),
        .library(name: "RoutePlanningService", targets: ["RoutePlanningService"]),
        .library(name: "SavedPlacesService", targets: ["SavedPlacesService"]),
        .library(name: "CommunityService", targets: ["CommunityService"]),
        .library(name: "TripService", targets: ["TripService"]),
        .library(name: "LiveUpdateService", targets: ["LiveUpdateService"]),
        .library(name: "EntitlementService", targets: ["EntitlementService"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(path: "../MapboxKit"),
    ],
    targets: [
        .target(
            name: "AuthService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .target(
            name: "VehicleService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .target(
            name: "StationService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .target(
            name: "PlaceService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "SearchEngine", package: "MapboxKit"),
            ]
        ),
        .target(
            name: "RoutePlanningService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
            ]
        ),
        .target(
            name: "SavedPlacesService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .target(
            name: "CommunityService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
            ]
        ),
        .target(
            name: "TripService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .target(
            name: "LiveUpdateService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Networking", package: "Core"),
            ]
        ),
        .target(
            name: "EntitlementService",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "Telemetry", package: "Core"),
                .product(name: "Storage", package: "Core"),
            ]
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: [
                "AuthService",
                "VehicleService",
                "StationService",
                "PlaceService",
                "RoutePlanningService",
                "SavedPlacesService",
                "CommunityService",
                "TripService",
                "LiveUpdateService",
                "EntitlementService",
            ]
        ),
    ]
)
