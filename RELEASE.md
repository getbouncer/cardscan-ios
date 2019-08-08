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

   
