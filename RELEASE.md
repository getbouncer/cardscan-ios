# Release process

## Shipping a new version

Once we have a build on master we want to publish:

1. Run CardScan systems iOS test

2. If a new file is added in `CardScan/`, run `pod install` and commit the newly created `Pod/` directory

3. Verify Carthage build is working

   ```bash
   carthage build --no-skip-current
   ```

4. Tag release

   ```bash
   git tag <version>
   git push --tags
   ```

5. Publish to CocoaPods

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