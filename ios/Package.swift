import PackageDescription

let package = Package(
    name: "pdf_combiner",
    platforms: [
        .iOS("12.0"),
        .macOS("10.11"),
    ],
    products: [
        // Expose a single library product used by the example's generated package
        .library(name: "pdf-combiner", targets: ["pdf_combiner_ios", "pdf_combiner_macos"]),
    ],
    dependencies: [],
    targets: [
        // iOS target (uses sources under ios/pdf_combiner/Sources/pdf_combiner)
        .target(
            name: "pdf_combiner_ios",
            path: "ios/pdf_combiner/Sources/pdf_combiner",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .target(
            name: "pdf_combiner_macos",
            path: "macos/pdf_combiner/Sources/pdf_combiner",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)

