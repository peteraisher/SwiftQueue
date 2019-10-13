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
    
    func checkedAppend<T: Equatable>(queue: inout SwiftQueue<T>, element: T) {
        let count = queue.count
        let first = queue.first
        queue.append(element)
        XCTAssertEqual(queue.count, count + 1)
        guard let last = queue.last else {
            XCTFail("queue.last unexpectedly returned nil")
            return
        }
        XCTAssertEqual(last, element)
        if count > 0 { // don't check if queue was previously empty
            XCTAssertEqual(first, queue.first, "Appended \(element) but first changed from \(String(describing: first)) to \(String(describing: queue.first))")
        }
    }
    
    func checkedPopOrRemoveFirst<T: Equatable>(queue: inout SwiftQueue<T>) {
        let count = queue.count
        guard count > 0 else {
            XCTAssertNil(queue.popFirst())
            return
        }
        guard let first = queue.first else {
            XCTFail("queue.count > 0 but queue.first == nil")
            return
        }
        let last = queue.last
        let removed = queue.removeFirst()
        XCTAssertEqual(removed, first)
        XCTAssertEqual(queue.count, count - 1)
        if count > 1 { // don't check if we've removed the only element
            XCTAssertEqual(queue.last, last)
        }
    }
    
    func checkedInsertElement<T: Equatable>(queue: inout SwiftQueue<T>, element: T, at index: Int) {
        let count = queue.count
        let previous = queue[index]
        let first = queue.first
        let last = queue.last
        queue.insert(element, at: index)
        XCTAssertEqual(queue.count, count + 1)
        XCTAssertEqual(queue[index], element)
        XCTAssertEqual(queue[index + 1], previous)
        if index > 0 { // if we inserted anywhere other than the start
            XCTAssertEqual(first, queue.first)
        }
        if index < count - 1 { // if we inserted anywhere other than the end
            XCTAssertEqual(last, queue.last)
        }
    }
    func checkedInsertContents<T: Equatable>(queue: inout SwiftQueue<T>, elements: [T], at index: Int) {
        let count = queue.count
        let previous = queue[index]
        let first = queue.first
        let last = queue.last
        queue.insert(contentsOf: elements, at: index)
        XCTAssertEqual(queue.count, count + elements.count)
        for i in 0 ..< elements.count {
            XCTAssertEqual(queue[index + i], elements[i])
        }
        XCTAssertEqual(queue[index + elements.count], previous)
        if index > 0 { // if we inserted anywhere other than the start
            XCTAssertEqual(first, queue.first)
        }
        if index < count - 1 { // if we inserted anywhere other than the end
            XCTAssertEqual(last, queue.last)
        }
    }
    
    func checkedRemoveAll<T>(queue: inout SwiftQueue<T>, keepingCapacity: Bool) {
        queue.removeAll(keepingCapacity: keepingCapacity)
        XCTAssert(queue.isEmpty)
        XCTAssertEqual(queue.count, 0)
    }
    
    func checkedCopyAndModifyOriginal<T: Equatable>(queue: inout SwiftQueue<T>, using checkedModification: (inout SwiftQueue<T>) -> ()) {
        let first = queue.first
        let last = queue.last
        let count = queue.count
        let copy = queue
        
        checkedModification(&queue)
        
        XCTAssertEqual(first, copy.first)
        XCTAssertEqual(last, copy.last)
        XCTAssertEqual(count, copy.count)
    }
    
    func checkedCopyAndModifyCopy<T: Equatable>(queue: inout SwiftQueue<T>, using checkedModification: (inout SwiftQueue<T>) -> ()) {
        let first = queue.first
        let last = queue.last
        let count = queue.count
        var copy = queue
        
        checkedModification(&copy)
        
        XCTAssertEqual(first, queue.first)
        XCTAssertEqual(last, queue.last)
        XCTAssertEqual(count, queue.count)
    }
    
    func checkedInitWithContents<T: Equatable>(elements: [T]) {
        let queue = SwiftQueue(elements)
        
        XCTAssertEqual(queue.count, elements.count)
        
        for pair in zip(queue, elements) {
            XCTAssertEqual(pair.0, pair.1)
        }
    }
    
    func checkedInitRepeatedValue<T: Equatable>(repeatedValue: T, count: Int) {
        let queue = SwiftQueue(repeating: repeatedValue, count: count)
        
        XCTAssertEqual(queue.count, count)
        for element in queue {
            XCTAssertEqual(element, repeatedValue)
        }
    }
    
    func testInitCountZero() {
        
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
        
        queue.append(5)
        queue.append(6)
        XCTAssertEqual(queue.removeFirst(), 5)
        queue.append(7)
        XCTAssertEqual(queue.removeFirst(), 6)
        XCTAssertEqual(queue.removeFirst(), 7)
        
    }
    
    func testAppendAndRemoveValueType() {
        var queue = SwiftQueue<Int>()
        
        checkedAppend(queue: &queue, element: 4)
        
        checkedPopOrRemoveFirst(queue: &queue)
        
        XCTAssert(queue.isEmpty)
    }
    
    func testAppendAndRemoveReferenceType() {
        var queue = SwiftQueue<Dummy>()
        checkedAppend(queue: &queue, element: Dummy(4))
        
        checkedPopOrRemoveFirst(queue: &queue)
        
        XCTAssert(queue.isEmpty)
    }
    
    func testInitContentsOfValueType() {
        checkedInitWithContents(elements: Array(2 ..< 30))
    }
    
    func testInitContentsOfReferenceType() {
        checkedInitWithContents(elements: Array((2 ..< 30).map({Dummy($0)})))
    }
    
    func testInitRepeatedValue() {
        checkedInitRepeatedValue(repeatedValue: 5, count: 10)
    }
    
    func testInitRepeatedValueReference() {
        checkedInitRepeatedValue(repeatedValue: Dummy(5), count: 10)
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
        checkedInsertElement(queue: &queue, element: 7, at: secondIndex)
    }
    
    func testInsertContentsOf() {
        var queue = SwiftQueue(1 ... 5)
        let elements = Array(7 ... 9)
        
        let secondIndex = queue.index(after: queue.startIndex)
        checkedInsertContents(queue: &queue, elements: elements, at: secondIndex)
        
        let thirdIndex = queue.index(after: secondIndex)
        checkedInsertContents(queue: &queue, elements: [20], at: thirdIndex)
        
        checkedInsertContents(queue: &queue, elements: [], at: thirdIndex)
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
        XCTAssertEqual(a.count, 4)
        b.append(20)
        XCTAssertEqual(b.count, 6)
        
        let arrayA = Array(a)
        let arrayB = Array(b)
        
        XCTAssertNotEqual(arrayA, arrayB)
        
        XCTAssertEqual(arrayA, [2, 3, 4, 5])
        XCTAssertEqual(arrayB, [1, 2, 3, 4, 5, 20])
    }
    
    func testRandomModifications() {
        var queue = SwiftQueue( 0 ..< 10 )
        var random = SystemRandomNumberGenerator()
        func randomIndex(count: Int) -> Int {
            return Int(random.next(upperBound: UInt(count)))
        }
        func randomValue() -> Int {
            return Int(random.next(upperBound: UInt(Int.max)))
        }
        func randomAction(queue: inout SwiftQueue<Int>) {
            switch random.next(upperBound: UInt(60)) {
            case 0 ..< 10:
                checkedAppend(queue: &queue, element: randomValue())
            case 10 ..< 30:
                checkedPopOrRemoveFirst(queue: &queue)
            case 30 ..< 35:
                if queue.count == 0 {
                    checkedAppend(queue: &queue, element: randomValue())
                    return
                }
                checkedInsertElement(queue: &queue,
                                     element: randomValue(),
                                     at: randomIndex(count: queue.count))
            case 35 ..< 40:
                let insertionLength = randomIndex(count: queue.count * 2 + 10)
                let elements = (0 ..< insertionLength).map {_ in randomValue() }
                if queue.count == 0 {
                    queue = SwiftQueue(elements)
                    return
                }
                checkedInsertContents(queue: &queue, elements: elements, at: randomIndex(count: queue.count))
            case 40:
                checkedRemoveAll(queue: &queue, keepingCapacity: false)
            case 41:
                checkedRemoveAll(queue: &queue, keepingCapacity: true)
            case 42 ..< 50:
                for _ in 0 ..< randomIndex(count: 20) {
                    checkedAppend(queue: &queue, element: randomValue())
                }
            case 50 ..< 60:
                for _ in 0 ..< randomIndex(count: 20) {
                    checkedPopOrRemoveFirst(queue: &queue)
                }
            default:
                return
            }
        }
        for _ in 0 ..< 1000 {
            switch random.next(upperBound: UInt(100)) {
            case 0 ..< 5:
                checkedCopyAndModifyOriginal(queue: &queue, using: randomAction)
            case 5 ..< 10:
                checkedCopyAndModifyCopy(queue: &queue, using: randomAction)
            default:
                randomAction(queue: &queue)
            }
            
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
    ("testInitRepeatedValueReference", testInitRepeatedValueReference),
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
    ("testRandomModifications", testRandomModifications),
    ]
}
