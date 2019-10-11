import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftQueueTests.allTests),
        testCase(SwiftQueuePerformanceTests.allTests),
    ]
}
#endif
