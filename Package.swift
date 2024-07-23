// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bluetooth-law-energy-swift",
    platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "bluetooth-law-energy-swift",
            targets: ["bluetooth-law-energy-swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/The-Igor/retry-policy-service.git", branch : "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "bluetooth-law-energy-swift",
            dependencies: [
                .product(name: "retry-policy-service", package: "retry-policy-service"),
            ]),
        .testTarget(
            name: "bluetooth-law-energy-swiftTests",
            dependencies: ["bluetooth-law-energy-swift"]),
    ]
)
