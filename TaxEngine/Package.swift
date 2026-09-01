// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TaxEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TaxEngine", targets: ["TaxEngine"])
    ],
    targets: [
        .target(name: "TaxEngine"),
        .testTarget(name: "TaxEngineTests", dependencies: ["TaxEngine"])
    ]
)
