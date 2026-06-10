// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "TouchBarCodexToken",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "TouchBarCodexToken", targets: ["TouchBarCodexToken"])
    ],
    targets: [
        .executableTarget(
            name: "TouchBarCodexToken",
            path: "Sources"
        )
    ]
)
