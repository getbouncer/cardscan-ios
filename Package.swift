// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CardScan",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "CardScan",
            targets: ["CardScan"]
        ),
    ],
    dependencies: [],
    targets: [
//        .binaryTarget(
//            name: "CardScan",
//            url: "https://downloads.getbouncer.com/swift_package_manager/1.0.5052/CardScan.xcframework.zip",
//            checksum: "a521b121abe9edf712fb480a9ea1bddd5b994e4a205c2aae72ef1c6387a778db"
//        )
        .binaryTarget(
            name: "CardScan",
            path: "XCFramework/CardScan_2.xcframework"
        )
    ]
)
