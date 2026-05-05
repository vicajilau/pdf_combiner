// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "pdf_combiner",
    platforms: [
        .iOS("12.0"),
        .macOS("10.11"),
    ],
    products: [
        // Two library products: one for iOS and one for macOS. When adding the package
        // to an Xcode project choose the product that matches the platform target.
        .library(name: "pdf_combiner_ios", targets: ["pdf_combiner_ios"]),
        .library(name: "pdf_combiner_macos", targets: ["pdf_combiner_macos"]),
        // Backwards-compatible product name expected by Flutter's generated Swift
        // package. Some Flutter tooling expects a product named "pdf-combiner";
        // provide it as a composite library that exposes both platform targets.
        .library(name: "pdf-combiner", targets: ["pdf_combiner_ios", "pdf_combiner_macos"]),
    ],
    targets: [
        .target(
            name: "pdf_combiner_ios",
            path: "ios/pdf_combiner/Sources/pdf_combiner",
            resources: [ .process("PrivacyInfo.xcprivacy") ]
        ),
        .target(
            name: "pdf_combiner_macos",
            path: "macos/pdf_combiner/Sources/pdf_combiner",
            resources: [ .process("PrivacyInfo.xcprivacy") ]
        ),
    ]
)


