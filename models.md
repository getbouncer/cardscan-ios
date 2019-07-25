For our models, cocoapods and mlmodels + apps that don't use
frameworks doesn't work. Originally we included the models as
resources and compiled them on the device, but this adds complexity
and overhead. Thus, we include generated model source code and the
associated mlmodelc data output from xcode directly in our pod instead
of letting the hosting apps translate mlmodels into these resources.

To get the mlmodelc directories, first you need to add the mlmodel
files to the project as source and re-install the pod in the Example
app. Then, from the Example directory you can run:

$ xcodebuild -workspace CardScan.xcworkspace \
    -scheme CardScan-Example \
    -derivedDataPath test_output \
    -configuration Debug \
    -sdk iphoneos build-for-testing

And the resulting mlmodelc files will be in:

$ ls test_output/Build/Products/Debug-iphoneos/CardScan/CardScan.framework/*.mlmodelc

