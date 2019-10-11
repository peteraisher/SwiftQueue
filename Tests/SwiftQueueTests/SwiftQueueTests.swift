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
        XCTAssert(queue.isEmpty)
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
        guard let last = queue.last else {
            XCTFail("queue.last was unexpectedly nil")
            return
        }
        XCTAssertEqual(first, 4)
        XCTAssertEqual(last, 4)
        
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, 4)
        XCTAssertEqual(queue.count, 0)
        XCTAssert(queue.isEmpty)
        XCTAssertNil(queue.first)
        XCTAssertNil(queue.last)
    }
    
    func testAppendAndRemoveReferenceType() {
        var queue = SwiftQueue<Dummy>()
        queue.append(Dummy(4))
        
        XCTAssertEqual(queue.count, 1)
        guard let first = queue.first else {
            XCTFail("queue.first was unexpectedly nil")
            return
        }
        guard let last = queue.last else {
            XCTFail("queue.last was unexpectedly nil")
            return
        }
        XCTAssertEqual(first, Dummy(4))
        XCTAssertEqual(last, Dummy(4))
        
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, Dummy(4))
        XCTAssertEqual(queue.count, 0)
        XCTAssert(queue.isEmpty)
        XCTAssertNil(queue.first)
        XCTAssertNil(queue.last)
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
        XCTAssertLessThan(startIndex, secondIndex)
    }
    
    func testFormIndexAfter() {
        let queue = SwiftQueue([1, 2])
        var firstIndex = queue.startIndex
        let secondIndex = queue.index(after: firstIndex)
        XCTAssertEqual(queue[firstIndex], 1)
        queue.formIndex(after: &firstIndex)
        XCTAssertEqual(secondIndex, firstIndex)
        XCTAssertEqual(queue[secondIndex], 2)
        XCTAssertEqual(queue[firstIndex], 2)
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
        
        queue.insert(contentsOf: [], at: thirdIndex)
        array.insert(contentsOf: [], at: arrayThirdIndex)
        
        XCTAssertEqual(queue.count, array.count)
        
        for pair in zip(queue, array) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }
    
    func testRemoveFirstK() {
        var queue = SwiftQueue(0 ..< 100)
        queue.removeFirst(20)
        XCTAssertEqual(queue.count, 80)
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, 20)
    }
    
    func testRemoveAll() {
        var queue = SwiftQueue(0 ..< 100)
        queue.removeAll()
        XCTAssertEqual(queue.count, 0)
        XCTAssert(queue.isEmpty)
    }
    
    func testPopFirst() {
        var queue = SwiftQueue(0 ..< 10)
        for i in 0 ..< 10 {
            guard let j = queue.popFirst() else {
                XCTFail("popFirst() unexpectedly returned nil")
                return
            }
            XCTAssertEqual(i, j)
        }
        XCTAssert(queue.isEmpty)
        XCTAssertEqual(queue.count, 0)
        XCTAssertNil(queue.popFirst())
    }
    
    func testValueSemantics() {
        var a = SwiftQueue(1 ... 5)
        var b = a
        _ = a.removeFirst()
        b.append(20)
        
        let arrayA = Array(a)
        let arrayB = Array(b)
        
        XCTAssertNotEqual(arrayA, arrayB)
        
        XCTAssertEqual(arrayA, [2, 3, 4, 5])
        XCTAssertEqual(arrayB, [1, 2, 3, 4, 5, 20])
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
    ("testFormIndexAfter", testFormIndexAfter),
    ("testSubscript", testSubscript),
    ("testInsert", testInsert),
    ("testInsertContentsOf", testInsertContentsOf),
    ("testRemoveFirstK", testRemoveFirstK),
    ("testRemoveAll", testRemoveAll),
    ("testPopFirst", testPopFirst),
    ("testValueSemantics", testValueSemantics),
    ]
}
