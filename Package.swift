// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CardScan",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "CardScan",
            targets: ["CardScan"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "CardScan",
            url: "https://downloads.getbouncer.com/swift_package_manager/2.0.0000-beta0/CardScan.xcframework.zip",
            checksum: "1c97eb468af92ce8cad8710e6b7a209c96bcb32b6f7c451327073b6535d238f5"
        )
    ]
)
