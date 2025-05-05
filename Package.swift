// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "mocktail",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "mocktail",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "mocktailTests",
            dependencies: [
                .targetItem(name: "mocktail", condition: .none),
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]
        ),
    ]
)
