First, create a branch for the private release:

```bash
git checkout -b cardscan-private-1.0.5044
```

Create a podspec for our private CardScan version:

```bash
cp CardScan.podspec CardScanPrivate.podspec
# open CardScanPrivate.podspec and update the name
s.name = 'CardScanPrivate'

# and update the `bundle_resource` names so that they're `CardScanPrivate`
core.resource_bundles = { 'CardScanPrivate'

# and

stripe.resource_bundles = { 'CardScanPrivate'
```

Update the `Podfile` to CardScanPrivate:

```bash
cd Example
# open Podfile
pod 'CardScanPrivate', :path => '../'
```

Install the new `CardScanPrivate` pod and open the workspace:

```bash
pod deintegrate; pod install
open CardScan.xcworkspace
```

Within Xcode update all of your imports:

```
import CardScan

should be

import CardScanPrivate
```

Update the bundle name to `CardScanPrivate` in `CSBundle`:

```swift
public static var bundleName = "CardScanPrivate"
```

In the `CardScan.storyboard` update the module in the following items from `CardScan` to `CardScanPrivate`:
- ScanViewController
- PreviewView
- BlurView
- CornerView

And then test CardScan to make sure that it works.

After it's all ready, push it to a branch so we can use it with Verify

```bash
git commit -a -m "Update module to CardScanPrivate"
git push --set-upstream origin cardscan-private-1.0.5044
```