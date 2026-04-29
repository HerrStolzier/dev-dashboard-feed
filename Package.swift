// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevDashboardFeed",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "DevDashboardFeed",
            targets: ["DevDashboardFeed"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "DevDashboardFeed",
            path: "Sources/DevDashboardFeed"
        ),
        .testTarget(
            name: "DevDashboardFeedTests",
            dependencies: ["DevDashboardFeed"],
            path: "Tests/DevDashboardFeedTests",
            resources: [
                .process("Fixtures")
            ]
        ),
    ]
)
