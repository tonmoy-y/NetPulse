// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetPulseCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NetPulseCore", targets: ["NetPulseCore"])
    ],
    targets: [
        .target(name: "NetPulseCore"),
        .testTarget(name: "NetPulseCoreTests", dependencies: ["NetPulseCore"])
    ]
)
