// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MacBookAnonymizer",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "MacBookAnonymizer",
            targets: ["MacBookAnonymizer"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MacBookAnonymizer",
            dependencies: [],
            path: "MacBookAnonymizer"
        ),
    ]
)
