# Deprecation Notice
Hello from the Stripe (formerly Bouncer) team!

We're excited to provide an update on the state and future of the [Card Scan OCR](https://github.com/stripe/stripe-ios/tree/master/StripeCardScan) product! As we continue to build into Stripe's ecosystem, we'll be supporting the mission to continuously improve the end customer experience in many of Stripe's core checkout products.

This SDK has been [migrated to Stripe](https://github.com/stripe/stripe-ios/tree/master/StripeCardScan) and is now free for use under the MIT license! The CardScan OCR API is currently getting built and will be free for use very soon!

If you are not currently a Stripe user, and interested in learning more about improving checkout experience through Stripe, please let us know and we can connect you with the team.

If you are not currently a Stripe user, and want to continue using the existing SDK, you can do so free of charge. Starting January 1, 2022, we will no longer be charging for use of the existing Bouncer Card Scan OCR SDK. For product support on [Android](https://github.com/stripe/stripe-android/issues) and [iOS](https://github.com/stripe/stripe-ios/issues). For billing support, please email [bouncer-support@stripe.com](mailto:bouncer-support@stripe.com).
For the new product, please visit the [stripe github repository](https://github.com/stripe/stripe-ios/tree/master/StripeCardScan).
# CardScan
This repository contains the open source code for the [Bouncer](https://www.getbouncer.com) CardScan product.

[CardScan](https://getbouncer.com/scan) is a relatively small library that provides fast and accurate payment card
scanning.

CardScan is the foundation for CardVerify enterprise libraries, which validate the authenticity of payment cards as
they are scanned.

![Unit Tests](https://github.com/getbouncer/cardscan-ios/workflows/Unit%20Tests/badge.svg)

![demo](docs/images/demo.gif)

## Contents
* [Requirements](#requirements)
* [Demo](#demo)
* [Installation](#installation)
* [Authors](#authors)
* [License](#license)

## Requirements
* Xcode 11 or higher
* iOS 11 or higher (but the scanning view controllers require iOS 11.2 or higher to run)
* iOS 13 or higher for name and expiry extraction

## Demo
This repository contains a demonstration app for the CardScan product. To build and run the demo app, follow the
instructions in the [demo documentation](https://docs.getbouncer.com/card-scan/android-integration-guide#demo).

## Installation
Follow the [installation instructions documentation](https://docs.getbouncer.com/card-scan/ios-integration-guide#installation)
for installing CardScan into your app.

## Authors
Sam King, Jaime Park, Adam Wushensky, Zain ul Abi Din, and Andy Li

## License
This library is available under the MIT license. See the [LICENSE](LICENSE) file for the full license text.
