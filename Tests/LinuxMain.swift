import XCTest

import BufferTests
import SwiftQueueTests
import SwiftQueuePerformanceTests

var tests = [XCTestCaseEntry]()
tests += BufferTests.allTests()
tests += SwiftQueueTests.allTests()
tests += SwiftQueuePerformanceTests.allTests()
XCTMain(tests)
