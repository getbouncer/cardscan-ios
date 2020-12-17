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
    echo 'uncomment before committing'
    #exit
fi

if [ -z "$(git tag | grep ${1})" ]; then
    echo "git tag is clean"
else
    echo "the tag ${1} already exists, bailing"
    exit
fi

PROD_BRANCH="production-$(date +"%Y%m%d-%s")"
git checkout -b $PROD_BRANCH

./scripts/build_xcframework.sh

# Copy the archive to Google Storage
gsutil cp build/CardScan.xcframework.zip  gs://bouncer-models/swift_package_manager/${1}/

# Setup the Package.swift file
touch Package.swift
git add Package.swift

checksum=`swift package compute-checksum build/CardScan.xcframework.zip`
url="https://downloads.getbouncer.com/swift_package_manager/${1}/CardScan.xcframework.zip"
python scripts/generate_package_swift.py ${url} ${checksum} < Package.template > Package.swift

# Push to prod branch for testing
git commit -a -m "Last commit for prod"
git push origin ${PROD_BRANCH}

./scripts/run_xcframework_test.sh ${PROD_BRANCH} "https://github.com/getbouncer/cardscan-ios.git"

git checkout .

# Success tag the branch and we're done
echo "xcarchive deployed successfully and tested, tagging branch"

git tag ${1}
git push origin ${PROD_BRANCH} --tags
