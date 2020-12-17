# CardScan developer's guide

With the v2 version of our CardScan library, we moved off of Cocoapods
for creating the build enviroment and shifted to a pure Xcode
setup. This guide describes how to build, test, and deploy this new
version of the CardScan library.

## Differences between v1 and v2

With v2 of CardScan, the general software API is largely unchanged,
but there are a few notable differences:

- We added support for Swift Package Manager and dropped support for
  Carthage (we may add Carthage back later). We still support
  Cocoapods.

- We moved away from source releases and use XCFramework to
  deploy. The main reason for this shift is to enable faster build
  times for apps that use the library and to simplify our bundle /
  resource handling (it's all packaged in the single XCFramework).

- We don't precompile our ML models explicity and allow Xcode to build
  them as a part of it's build process.

- We include our system tests (ie UI tests) directly in our workspace
  to enable automatic test validation as a part of our Github
  workflow.

These changes to the build and deploy process will hopefully make it
easier to build, deploy, and test CardScan.

## Build

To build CardScan, start by opening the top level
`CardScan.xcworkspace` in Xcode. Within this workspace there are three
projects: the main `CardScan.xcproject` that hosts the SDK, the
`CardScanExample.xcproject` app for manual testing of the library, and
the `CardScanSystemTest.xcproject` for automated UI tests.

Most people will want to select the `CardScanExample` target.

## Test

For testing, we have unit tests in the `CardScanExample` project and
UI tests in the `CardScanSystemTest` project.

## Deploy

You need to install a few python libraries and setup a venv before you
can run the deploy process. Your setup should look something like
this:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Please see the `scripts/deploy_xcframework.sh` script for more
details. From a high level the process is:

- Create a prod branch

- Generate the XCFramework and copy it to google cloud storage for testing

- Generate the `Package.swift` file for testing

- Test the branch

- Copy the XCFramework to google cloud storage for prod

- Generate the `Package.swift` file for release

- Test again

- Tag the prod branch with the release tag
