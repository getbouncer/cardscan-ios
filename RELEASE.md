# Release process

## Shipping a new version

Once we have a build on master we want to publish:

0. Bump the `CardScan.podspec` with the new version of our library

1. Run CardScan systems iOS test. Make sure to watch the videos to double check that everything looks good.

2. If a new file is added in `CardScan/`, run `pod install` and commit the newly created `Pod/` directory

3. Verify Carthage build is working

   ```bash
   carthage build --no-skip-current
   ```
   *  If you get the error: `no shared framework schemes`, reclick `shared` on the project schemes in xcode.

4. Run the Cocoapods linter to make sure that everything is going to pass

   ```bash
   pod lib lint
   ```

5. Tag release

   ```bash
   git tag <version>
   git push --tags
   ```

6. Publish to CocoaPods

   ```bash
   pod trunk push
   ```

### Bumping a model

1. Put the new model in the OriginalModels directory

2. Remove the old compiled version from the resources directory

   ```bash
   rm -rf CardScan/Assets/FindFour.mlmodelc
   ```
3. Compile the new model

   ```bash
   xcrun coremlc compile OriginalModels/FindFour.mlmodel CardScan/Assets
   ```
