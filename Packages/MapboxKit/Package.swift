// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MapboxKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MapEngine", targets: ["MapEngine"]),
        .library(name: "NavigationEngine", targets: ["NavigationEngine"]),
        .library(name: "SearchEngine", targets: ["SearchEngine"]),
        .library(name: "CarPlayKit", targets: ["CarPlayKit"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        // CLAUDE.md 5.3 kural 4: Mapbox sürümleri yalnızca burada tanımlanır. Navigation SDK
        // eklendiğinde Maps onun sabitlediği sürüme birlikte yükseltilir.
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.33.1"),
    ],
    targets: [
        .target(
            name: "MapEngine",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
            ]
        ),
        .target(
            name: "NavigationEngine",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "LocationKit", package: "Core"),
                .product(name: "LiveActivityModels", package: "Core"),
            ]
        ),
        .target(
            name: "SearchEngine",
            dependencies: [
                .product(name: "OnsarjCore", package: "Core"),
                .product(name: "OnsarjDomain", package: "Domain"),
            ]
        ),
        .target(
            name: "CarPlayKit",
            dependencies: [
                "MapEngine",
                "NavigationEngine",
                .product(name: "OnsarjDomain", package: "Domain"),
                .product(name: "DesignSystem", package: "Core"),
            ]
        ),
        .testTarget(
            name: "MapboxKitTests",
            dependencies: [
                "MapEngine",
                "NavigationEngine",
                "SearchEngine",
                "CarPlayKit",
            ]
        ),
    ]
)
