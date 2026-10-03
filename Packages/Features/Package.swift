// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "GarageFeature", targets: ["GarageFeature"]),
        .library(name: "HomeMapFeature", targets: ["HomeMapFeature"]),
        .library(name: "SearchFeature", targets: ["SearchFeature"]),
        .library(name: "SavedPlacesFeature", targets: ["SavedPlacesFeature"]),
        .library(name: "RoutePlanningFeature", targets: ["RoutePlanningFeature"]),
        .library(name: "NavigationFeature", targets: ["NavigationFeature"]),
        .library(name: "CarPlayFeature", targets: ["CarPlayFeature"]),
        .library(name: "StationDetailFeature", targets: ["StationDetailFeature"]),
        .library(name: "PlaceDetailFeature", targets: ["PlaceDetailFeature"]),
        .library(name: "CommunityFeature", targets: ["CommunityFeature"]),
        .library(name: "TripsFeature", targets: ["TripsFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(path: "../MapboxKit"),
    ],
    targets: [
        .target(
            name: "AuthFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "GarageFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "HomeMapFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
                .product(name: "MapEngine", package: "MapboxKit"),
            ]
        ),
        .target(
            name: "SearchFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
                .product(name: "MapEngine", package: "MapboxKit"),
            ]
        ),
        .target(
            name: "SavedPlacesFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "RoutePlanningFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
                .product(name: "MapEngine", package: "MapboxKit"),
            ]
        ),
        .target(
            name: "NavigationFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
                .product(name: "NavigationEngine", package: "MapboxKit"),
                .product(name: "MapEngine", package: "MapboxKit"),
                .product(name: "LiveActivityModels", package: "Core"),
            ]
        ),
        .target(
            name: "CarPlayFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
                .product(name: "CarPlayKit", package: "MapboxKit"),
                .product(name: "NavigationEngine", package: "MapboxKit"),
            ]
        ),
        .target(
            name: "StationDetailFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "PlaceDetailFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "CommunityFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "TripsFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "Localization", package: "Core"),
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "AuthFeature",
                "GarageFeature",
                "HomeMapFeature",
                "SearchFeature",
                "SavedPlacesFeature",
                "RoutePlanningFeature",
                "NavigationFeature",
                "CarPlayFeature",
                "StationDetailFeature",
                "PlaceDetailFeature",
                "CommunityFeature",
                "TripsFeature",
                "ProfileFeature",
            ]
        ),
    ]
)
