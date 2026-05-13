// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "S3Kit",
    platforms: [
        .iOS(.v13), .macOS(.v12), .tvOS(.v13), .visionOS(.v1)
    ],
    products: [
        .library(
            name: "S3Kit",
            targets: ["S3Kit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "4.5.0"),
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.18.1"),
    ],
    targets: [
        .target(
            name: "S3Kit",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "XMLCoder", package: "XMLCoder"),
            ]
        ),
        .testTarget(
            name: "S3KitTests",
            dependencies: ["S3Kit"],
            path: "Tests/S3KitTests",
        ),
        .testTarget(
            name: "S3KitIntegrationTests",
            dependencies: ["S3Kit"],
            path: "Tests/S3KitIntegrationTests",
        ),
    ],
    swiftLanguageModes: [.v6]
)
