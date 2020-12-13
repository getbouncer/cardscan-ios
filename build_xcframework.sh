#!/bin/bash

if [ -z "$1" ]; then
    echo Usage ${0}: version
    echo       for example:
    echo
    echo       ${0} 2.0.0000-beta0
    echo
fi

rm -rf build

xcodebuild archive \
  -workspace CardScan.xcworkspace \
  -scheme CardScanExample \
  -destination "generic/platform=iOS" \
  -archivePath "build/CardScanArchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive \
  -workspace CardScan.xcworkspace \
  -scheme CardScanExample \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "build/CardScanSimulatorArchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework \
	   -framework "build/CardScanArchive.xcarchive/Products/Library/Frameworks/CardScan.framework" \
	   -framework "build/CardScanSimulatorArchive.xcarchive/Products/Library/Frameworks/CardScan.framework" \
	   -output build/CardScan.xcframework

cd build
zip -r CardScan.xcframework.zip CardScan.xcframework
cd ..

gsutil cp build/CardScan.xcframework.zip  gs://bouncer-models/swift_package_manager/${1}/
