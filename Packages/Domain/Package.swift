// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OnsarjDomain", targets: ["OnsarjDomain"])
    ],
    targets: [
        .target(name: "OnsarjDomain"),
        .testTarget(
            name: "DomainTests",
            dependencies: ["OnsarjDomain"]
        ),
    ]
)
