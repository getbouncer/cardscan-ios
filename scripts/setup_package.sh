#!/bin/bash

# if we get an error bail
set -euxo pipefail

if [[ -z "${1}" || -z "${2}" ]]; then
    echo "Usage ${0}: branch tag"
    exit
fi

# Copy the archive to Google Storage
gsutil cp build/CardScan.xcframework.zip  gs://bouncer-models/swift_package_manager/${2}/

# Setup the Package.swift file
touch Package.swift
git add Package.swift

checksum=`swift package compute-checksum build/CardScan.xcframework.zip`
url="https://downloads.getbouncer.com/swift_package_manager/${2}/CardScan.xcframework.zip"
python scripts/generate_package_swift.py ${url} ${checksum} < Package.template > Package.swift

# Push to prod branch for testing
git commit -a -m "Commit for package.swift update on ${2}"
git push origin ${1}
