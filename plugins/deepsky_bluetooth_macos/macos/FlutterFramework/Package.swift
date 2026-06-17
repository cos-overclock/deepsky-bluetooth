// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FlutterFramework",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterFramework", targets: ["FlutterMacOS"])
    ],
    targets: [
        .target(name: "FlutterMacOS")
    ]
)
