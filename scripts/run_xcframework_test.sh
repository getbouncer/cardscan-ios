#!/bin/bash

if [[ -z "$1"  ||  -z "$2"  || -z "$3" ]]; then
    echo Usage ${0}: branch repo_url xcframework_url
    echo       for example:
    echo
    echo       ${0} 2.0.0000-beta0 file:///Users/kingst/work/cardscan-ios file:///Users/kingst/work/cardscan-ios/build/CardScan.xcframework.zip
    echo
    exit
fi

source venv/bin/activate

url="${3}"
checksum=`swift package compute-checksum build/CardScan.xcframework.zip`
python scripts/generate_package_swift.py ${url} ${checksum} < Package.template > Package.swift

git commit -a -m "Prep for prod, run xcframework test"

cd SpmXCFrameworkTest

# super hacky but the best I could find https://stackoverflow.com/a/61110638
/usr/libexec/PlistBuddy -c "set :objects:3B24F191258B971900C47E4D:requirement:branch ${1}" SpmXCFrameworkTest.xcodeproj/project.pbxproj

/usr/libexec/PlistBuddy -c "set :objects:3B24F191258B971900C47E4D:repositoryURL ${2}" SpmXCFrameworkTest.xcodeproj/project.pbxproj


xcodebuild test -project SpmXCFrameworkTest.xcodeproj -scheme SpmXCFrameworkTest -destination 'platform=iOS Simulator,name=iPhone 11'
