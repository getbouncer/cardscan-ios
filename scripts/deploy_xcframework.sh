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

if [ -z "$(git tag | grep ${1})" ]; then
    echo "git tag is clean"
else
    echo "the tag ${1} already exists, bailing"
    exit
fi

PROD_BRANCH="production-$(date +"%Y%m%d-%s")"
git checkout -b $PROD_BRANCH

./scripts/build_xcframework.sh

./scripts/setup_package.sh ${PROD_BRANCH} ${PROD_BRANCH}

./scripts/run_xcframework_test.sh ${PROD_BRANCH} "https://github.com/getbouncer/cardscan-ios.git"

# we're all done, copy the prod archive and tag the prod branch
./scripts/setup_package.sh ${PROD_BRANCH} ${1}

# one last test
./scripts/run_xcframework_test.sh ${PROD_BRANCH} "https://github.com/getbouncer/cardscan-ios.git"

# Success tag the branch and we're done

echo "pushing to cocoapods"
python scripts/generate_podspec.py ${1} < CardScan.podspec.template > CardScan.podspec

cp -r build/CardScan.xcframework .
git add CardScan.xcframework
git add CardScan.podspec
git commit -a -m "Adding podspec"
git push origin ${PROD_BRANCH}
git tag ${1}
git push origin ${PROD_BRANCH} --tags

pod trunk push

echo "xcarchive deployed successfully"

git checkout master
