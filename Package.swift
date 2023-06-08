// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthKit",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "AuthKit",
            targets: ["AuthKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/square/Valet", exact: "4.1.3"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", exact: "1.7.1"),
        .package(url: "https://github.com/divar-ir/NetShears", exact: "3.4.2")
    ],
    targets: [
        .target(
            name: "AuthKit",
            dependencies: ["Valet", "CryptoSwift", "NetShears"]),
    ]
)
