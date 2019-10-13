import XCTest
@testable import SwiftQueue

final class BufferTests: XCTestCase {
    
    func testInitEmpty() {
        let buffer = _Buffer<Int>()
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.capacity, 0)
        XCTAssert(buffer.isEmpty)
    }

    static var allTests = [
    ("testInitEmpty", testInitEmpty),
    ]
}
