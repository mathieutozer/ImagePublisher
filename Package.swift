// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ImageTaskPublisher",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "ImageTaskPublisher", targets: ["ImageTaskPublisher"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", from: "8.0.0")
    ],
    targets: [
        .target(name: "ImageTaskPublisher", dependencies: ["Nuke"], path: "Source")
    ]
)
