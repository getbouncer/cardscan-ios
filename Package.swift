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
            url: "https://downloads.getbouncer.com/swift_package_manager/2.0.0000-beta2/CardScan.xcframework.zip",
            checksum: "2a36855e5c58b2c3683050e272c81b5bb1c25942de5857394c6369f6a93cbc68"
        )
    ]
)
