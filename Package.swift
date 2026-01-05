// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YeelightController",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "YeelightController", targets: ["YeelightController"])
    ],
    targets: [
        .executableTarget(
            name: "YeelightController",
            path: "YeelightController"
        )
    ]
)
