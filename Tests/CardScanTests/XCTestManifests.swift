import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(cardscan_iosTests.allTests),
    ]
}
#endif
