// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SiOrNoGoobledygook",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "SiOrNoGoobledygook",
            targets: ["SiOrNoGoobledygook"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SiOrNoGoobledygook",
            dependencies: [],
            path: "SiOrNoGoobledygook"
        ),
    ]
)
