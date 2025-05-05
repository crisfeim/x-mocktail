// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MockTail",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MockTail",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "MockTailTests",
            dependencies: [
                .targetItem(name: "MockTail", condition: .none),
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]
        ),
    ]
)
