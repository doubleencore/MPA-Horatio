// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Horatio",
        platforms: [
        .iOS("11.0"),
        .watchOS("4.0"),
        .tvOS("11.0")
    ],
    products: [
        .library(
            name: "Horatio",
            targets: ["Horatio"],
            swiftSettings: [
                #if ENABLE_HEALTHKIT
                .define("ENABLE_HEALTHKIT")
                #endif
            ]
            ),
        .library(
            name: "Horatio-HealthKit",
            targets: ["Horatio-HealthKit"]),
    ],
    targets: [
        .target(
            name: "Horatio",
            path: "Horatio/Horatio"),
        .testTarget(
            name: "HoratioTests",
            dependencies: ["Horatio"],
            path: "Horatio/HoratioTests")
    ]
)
