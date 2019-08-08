# Release process

## Shipping a new version

Once we have a build on master we want to publish:

1. Run CardScan systems iOS test

2. Tag release

   ```bash
   git tag <version>
   git push --tags
   ```

3. Publish to CocoaPods

   ```bash
   pod trunk push
   ```

   
