xcodebuild archive \
  -workspace CardScan.xcworkspace \
  -scheme CardScan_Example \
  -destination "generic/platform=iOS" \
  -archivePath "CardScanArchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive \
  -workspace CardScan.xcworkspace \
  -scheme CardScan_Example \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "CardScanSimulatorArchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework \
           -framework "CardScanArchive.xcarchive/Products/Library/Frameworks/CardScan.framework" \
           -framework "CardScanSimulatorArchive.xcarchive/Products/Library/Frameworks/CardScan.framework" \
           -output CardScan.xcframework

