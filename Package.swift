// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ImagePublisher",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "ImagePublisher", targets: ["ImagePublisher"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", from: "9.0.0")
    ],
    targets: [
        .target(name: "ImagePublisher", dependencies: ["Nuke"], path: "Source")
    ]
)
