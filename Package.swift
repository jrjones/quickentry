// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QuickEntry",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "QuickEntry",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TOMLKit", package: "TOMLKit"),
            ]
        ),
    ]
)
