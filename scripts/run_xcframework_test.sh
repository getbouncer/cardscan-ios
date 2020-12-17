#!/bin/bash

# if we get an error bail
set -euxo pipefail

if [[ -z "$1"  ||  -z "$2" ]]; then
    echo Usage ${0}: branch repo_url
    echo       for example:
    echo
    echo       ${0} 2.0.0000-beta0 https://github.com/getbouncer/cardscan-ios.git
    echo
    exit
fi

source venv/bin/activate

cd SpmXCFrameworkTest

# super hacky but the best I could find https://stackoverflow.com/a/61110638
/usr/libexec/PlistBuddy -c "set :objects:3B24F191258B971900C47E4D:requirement:branch ${1}" SpmXCFrameworkTest.xcodeproj/project.pbxproj

/usr/libexec/PlistBuddy -c "set :objects:3B24F191258B971900C47E4D:repositoryURL ${2}" SpmXCFrameworkTest.xcodeproj/project.pbxproj

xcodebuild clean -project SpmXCFrameworkTest.xcodeproj -scheme SpmXCFrameworkTest -destination 'platform=iOS Simulator,name=iPhone 11'

xcodebuild test -project SpmXCFrameworkTest.xcodeproj -scheme SpmXCFrameworkTest -destination 'platform=iOS Simulator,name=iPhone 11'

git checkout .

cd ..

