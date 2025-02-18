// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdf_combiner",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "pdf-combiner", targets: ["pdf_combiner"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "pdf_combiner",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
