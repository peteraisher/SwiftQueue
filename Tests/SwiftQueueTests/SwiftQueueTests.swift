import XCTest
@testable import SwiftQueue

final class SwiftQueueTests: XCTestCase {
    
    final class Dummy: Equatable {
        static func == (lhs: Dummy, rhs: Dummy) -> Bool {
            return lhs.number == rhs.number
        }
        static func != (lhs: Dummy, rhs: Dummy) -> Bool {
            return lhs.number != rhs.number
        }
        
        let number: Int
        init(_ number: Int) { self.number = number }
        
    }
    
    func testInitCountZero() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let queue = SwiftQueue<Int>()
        
        XCTAssertEqual(queue.count, 0)
    }
    
    
    func testCorrectOrdering() {
        var queue = SwiftQueue<Int>()
        
        queue.append(2)
        queue.append(3)
        queue.append(4)
        
        XCTAssertEqual(queue.removeFirst(), 2)
        XCTAssertEqual(queue.removeFirst(), 3)
        XCTAssertEqual(queue.removeFirst(), 4)
    }
    
    func testAppendAndRemoveValueType() {
        var queue = SwiftQueue<Int>()
        queue.append(4)
        
        XCTAssertEqual(queue.count, 1)
        guard let first = queue.first else {
            XCTFail("queue.first was unexpectedly nil")
            return
        }
        XCTAssertEqual(first, 4)
        
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, 4)
        XCTAssertEqual(queue.count, 0)
    }
    
    func testAppendAndRemoveReferenceType() {
        var queue = SwiftQueue<Dummy>()
        queue.append(Dummy(4))
        
        XCTAssertEqual(queue.count, 1)
        guard let first = queue.first else {
            XCTFail("queue.first was unexpectedly nil")
            return
        }
        XCTAssertEqual(first, Dummy(4))
        
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, Dummy(4))
        XCTAssertEqual(queue.count, 0)
    }
    
    func testInitContentsOfValueType() {
        let other = Array(2 ..< 30)
        let queue = SwiftQueue(other)
        
        XCTAssertEqual(queue.count, other.count)
        
        for pair in zip(queue, other) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }
    
    func testInitContentsOfReferenceType() {
        let other = Array((2 ..< 30).map({Dummy($0)}))
        let queue = SwiftQueue(other)
        
        XCTAssertEqual(queue.count, other.count)
        
        for pair in zip(queue, other) {
            XCTAssert(pair.0 === pair.1)
        }
    }
    
    func testInitRepeatedValue() {
        let queue = SwiftQueue(repeating: 5, count: 10)
        let array = Array(repeating: 5, count: 10)
        XCTAssertEqual(queue.count, array.count)
        
        for pair in zip(queue, array) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }
    
    func testInitFromArrayLiteral() {
        let queue: SwiftQueue = [1, 3, 5, 7, 9]
        let array = [1, 3, 5, 7, 9]
        
        XCTAssertEqual(queue.count, array.count)
        
        for pair in zip(queue, array) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }
    
    func testIndexComparison() {
        let queue = SwiftQueue([1,2,3])
        XCTAssertLessThan(queue.startIndex, queue.endIndex)
    }
    
    func testEmptyIndex() {
        let queue = SwiftQueue<Int>()
        let startIndex = queue.startIndex
        let endIndex = queue.endIndex
        XCTAssertEqual(startIndex, endIndex)
    }
    
    func testIndexAfter() {
        let queue = SwiftQueue([1])
        let startIndex = queue.startIndex
        let secondIndex = queue.index(after: startIndex)
        XCTAssertEqual(secondIndex, queue.endIndex)
        let thirdIndex = queue.index(after: secondIndex)
        XCTAssertLessThan(secondIndex, thirdIndex)
    }
    
    func testSubscript() {
        var queue = SwiftQueue(1 ... 5)
        let startIndex = queue.startIndex
        XCTAssertEqual(queue[startIndex], 1)
        let secondIndex = queue.index(after: startIndex)
        XCTAssertEqual(queue[secondIndex], 2)
        queue[secondIndex] = 10
        XCTAssertEqual(queue[secondIndex], 10)
    }
    
    func testInsert() {
        var queue = SwiftQueue(1 ... 5)
        let secondIndex = queue.index(after: queue.startIndex)
        XCTAssertEqual(queue[secondIndex], 2)
        queue.insert(7, at: secondIndex)
        XCTAssertEqual(queue[secondIndex], 7)
        let thirdIndex = queue.index(after: secondIndex)
        XCTAssertEqual(queue[thirdIndex], 2)
    }
    
    func testInsertContentsOf() {
        var queue = SwiftQueue(1 ... 5)
        let secondIndex = queue.index(after: queue.startIndex)
        queue.insert(contentsOf: (7 ... 9), at: secondIndex)
        var array = Array(1 ... 5)
        let arraySecondIndex = array.index(after: array.startIndex)
        array.insert(contentsOf: (7 ... 9), at: arraySecondIndex)
        
        XCTAssertEqual(queue.count, array.count)
        
        for pair in zip(queue, array) {
            XCTAssertEqual(pair.0, pair.1)
        }
        
        let thirdIndex = queue.index(after: secondIndex)
        let arrayThirdIndex = array.index(after: arraySecondIndex)
        
        queue.insert(contentsOf: [20], at: thirdIndex)
        array.insert(contentsOf: [20], at: arrayThirdIndex)
        
        XCTAssertEqual(queue.count, array.count)
        
        for pair in zip(queue, array) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }

    static var allTests = [
    ("testInitCountZero", testInitCountZero),
    ("testCorrectOrdering", testCorrectOrdering),
    ("testAppendAndRemoveValueType", testAppendAndRemoveValueType),
    ("testAppendAndRemoveReferenceType", testAppendAndRemoveReferenceType),
    ("testInitContentsOfValueType", testInitContentsOfValueType),
    ("testInitContentsOfReferenceType", testInitContentsOfReferenceType),
    ("testInitRepeatedValue", testInitRepeatedValue),
    ("testInitFromArrayLiteral", testInitFromArrayLiteral),
    ("testIndexComparison", testIndexComparison),
    ("testEmptyIndex", testEmptyIndex),
    ("testIndexAfter", testIndexAfter),
    ("testSubscript", testSubscript),
    ("testInsert", testInsert),
    ("testInsertContentsOf", testInsertContentsOf),
    ]
}
