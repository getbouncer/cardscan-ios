#!/bin/bash

# if we get an error bail
set -euxo pipefail

if [ -z "$1" ]; then
    echo Usage ${0}: version
    echo       for example:
    echo
    echo       ${0} 2.0.0000-beta0
    echo
    exit
fi

rm -rf build

if [ -z "$(git status --porcelain)" ]; then
    echo 'git status is clean'
else
    echo 'uncommitted changes, run `git status` for more information'
    exit
fi

if [ "$(git symbolic-ref --short HEAD)" != "master" ]; then
    echo 'will only deploy from master branch, bailing'
    exit
fi

PROD_BRANCH="production-$(date +"%Y%m%d-%s")"
git checkout -b $PROD_BRANCH

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

git commit -a -m "Prep for prod"

source venv/bin/activate

url="file://`pwd`/build/CardScan.xcframework.zip"
checksum=`swift package compute-checksum build/CardScan.xcframework.zip`
python scripts/generate_package_swift.py ${url} ${checksum} < Package.template > Package.swift

exit

gsutil cp build/CardScan.xcframework.zip  gs://bouncer-models/swift_package_manager/${1}/

url="https://downloads.getbouncer.com/swift_package_manager/${1}/CardScan.xcframework.zip"
python scripts/generate_package_swift.py ${url} ${checksum} < Package.template > Package.swift

