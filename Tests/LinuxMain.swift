import XCTest

import SwiftQueueTests

var tests = [XCTestCaseEntry]()
tests += SwiftQueueTests.allTests()
tests += SwiftQueuePerformanceTests.allTests()
XCTMain(tests)
