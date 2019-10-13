import XCTest

import SwiftQueueTests

var tests = [XCTestCaseEntry]()
tests += BufferTests.allTests()
tests += SwiftQueueTests.allTests()
tests += SwiftQueuePerformanceTests.allTests()
XCTMain(tests)
