// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CardScan",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CardScan",
            targets: ["CardScan"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
//        .package(name: "Stripe", url:"https://github.com/stripe/stripe-ios.git", from: "20.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "Stripe",
            url: "https://github.com/stripe/stripe-ios/releases/download/v19.3.0/Stripe.xcframework.zip",
            checksum: "fe459dd443beee5140018388fd6933e09b8787d5b473ec9c2234d75ff0d968bd"),
        .target(
            name: "CardScan",
            dependencies: ["Stripe", "UIKit"]),

        //https://github.com/stripe/stripe-ios/releases/download/20.1.1/Stripe.xcframework.zip
        //67865abafbe168f768bb40fe417f9977338f90847bfda25592fb33a22730d0c4
        .testTarget(
            name: "CardScanTests",
            dependencies: ["CardScan"])
    ],
    swiftLanguageVersions: [.v5]
)
