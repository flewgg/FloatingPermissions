// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "FloatingPermissions",
    products: [
        .library(
            name: "FloatingPermissions",
            targets: ["FloatingPermissions"]
        ),
    ],
    targets: [
        .target(
            name: "FloatingPermissions"
        ),
        .testTarget(
            name: "FloatingPermissionsTests",
            dependencies: ["FloatingPermissions"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
