import XCTest
@testable import SwiftQueue

final class SwiftQueuePerformanceTests: XCTestCase {
    
    let numItems: Int = 10_000
    
    final class Dummy: Equatable {
        let number: Int
        init(_ number: Int) { self.number = number }
        static func == (lhs: Dummy, rhs: Dummy) -> Bool {
            return lhs.number == rhs.number
        }
    }
    
    func testCreateValueType() {
        
        let items = Array(0 ..< numItems)
        
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            startMeasuring()
            let queue = SwiftQueue(items)
            XCTAssertEqual(queue.count, numItems)
            stopMeasuring()
            let array = Array(queue)
            XCTAssertEqual(array, items)
        }
        
    }
    
    func testCreateReferenceType() {
        
        let items = Array((0 ..< numItems).map({Dummy($0)}))
        
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            startMeasuring()
            let queue = SwiftQueue(items)
            XCTAssertEqual(queue.count, numItems)
            stopMeasuring()
            let array = Array(queue)
            XCTAssertEqual(array, items)
        }
    }
    
    func testDeepCopyValueType() {
        let original = SwiftQueue(0 ..< numItems)
        
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            startMeasuring()

            var copy = original
            copy.append(numItems)
            
            XCTAssertEqual(copy.count, numItems + 1)
            stopMeasuring()
            
            XCTAssertEqual(Array(copy), original + [numItems])
        }
    }
    
    func testDeepCopyReferenceType() {
        let original = SwiftQueue((0 ..< numItems).map({Dummy($0)}))
        
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            startMeasuring()
            var copy = original
            
            copy.append(Dummy(numItems))
            
            XCTAssertEqual(copy.count, numItems + 1)
            stopMeasuring()
            
            XCTAssertEqual(Array(copy), original + [Dummy(numItems)])
            
        }
    }
    
    func testRemoveFirstValueType() {
        
        measureMetrics(SwiftQueuePerformanceTests.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            var original = SwiftQueue(0 ..< numItems)
            startMeasuring()
            for _ in 0 ..< numItems - 1 {
                _ = original.removeFirst()
            }
            let actual = original.removeFirst()
            stopMeasuring()
            XCTAssertEqual(actual, numItems - 1)
        }
    }
    
    func testAlternatingAppendAndRemove() {
        var queue = SwiftQueue<Int>()
        measure {
            for i in 0 ..< numItems {
                if i % 3 == 2 { _ = queue.removeFirst() }
                else { queue.append(i) }
            }
            for i in 0 ..< numItems {
                if i % 3 == 0 { queue.append(i) }
                else { _ = queue.removeFirst() }
            }
        }
    }
    
    
    func testRandomModifications() {
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
                queue.append(randomValue())
            case 10 ..< 30:
                queue.popFirst()
            case 30 ..< 35:
                if queue.count == 0 {
                    queue.append(randomValue())
                    return
                }
                queue.insert(randomValue(), at: randomIndex(count: queue.count))
            case 35 ..< 40:
                let insertionLength = randomIndex(count: queue.count * 2 + 10)
                let elements = (0 ..< insertionLength).map {_ in randomValue() }
                if queue.count == 0 {
                    queue = SwiftQueue(elements)
                    return
                }
                queue.insert(contentsOf: elements, at: randomIndex(count: queue.count))
            case 40:
                queue.removeAll(keepingCapacity: false)
            case 41:
                queue.removeAll(keepingCapacity: true)
            case 42 ..< 50:
                for _ in 0 ..< randomIndex(count: 20) {
                    queue.append(randomValue())
                }
            case 50 ..< 60:
                for _ in 0 ..< randomIndex(count: 20) {
                    queue.popFirst()
                }
            default:
                return
            }
        }
        measure {
            var queue = SwiftQueue( 0 ..< 10 )
            for _ in 0 ..< 1000 {
                switch random.next(upperBound: UInt(100)) {
                case 0 ..< 5:
                    let copy = queue
                    randomAction(queue: &queue)
                    _fixLifetime(copy)
                case 5 ..< 10:
                    var copy = queue
                    randomAction(queue: &copy)
                default:
                    randomAction(queue: &queue)
                }
                
            }
        }
        
    }

    static var allTests = [
    ("testCreateValueType", testCreateValueType),
    ("testCreateReferenceType", testCreateReferenceType),
    ("testDeepCopyValueType", testDeepCopyValueType),
    ("testDeepCopyReferenceType", testDeepCopyReferenceType),
    ("testRemoveFirstValueType", testRemoveFirstValueType),
    ("testAlternatingAppendAndRemove", testAlternatingAppendAndRemove),
    ]
}

