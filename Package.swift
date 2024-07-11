// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bluetooth-law-energy-swift",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "bluetooth-law-energy-swift",
            targets: ["bluetooth-law-energy-swift"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "bluetooth-law-energy-swift"),
        .testTarget(
            name: "bluetooth-law-energy-swiftTests",
            dependencies: ["bluetooth-law-energy-swift"]),
    ]
)
