import XCTest
@testable import SwiftQueue

final class SwiftQueuePerformanceTests: XCTestCase {
    
    let numItems: Int = 10_000
    
    final class Dummy {
        let number: Int
        init(_ number: Int) { self.number = number }
    }
    
    func testCreateValueType() {
        
        let items = Array(0 ..< numItems)
        
        measure {
            let queue = SwiftQueue(items)
            XCTAssertEqual(queue.count, numItems)
        }
        
    }
    
    func testCreateReferenceType() {
        
        let items = Array((0 ..< numItems).map({Dummy($0)}))
        
        measure {
            let queue = SwiftQueue(items)
            XCTAssertEqual(queue.count, numItems)
        }
    }
    
    func testDeepCopyValueType() {
        let original = SwiftQueue(0 ..< numItems)
        
        measure {
            var copy = original
            
            copy.append(numItems)
            
            XCTAssertEqual(copy.count, numItems + 1)
        }
    }
    
    func testDeepCopyReferenceType() {
        let original = SwiftQueue((0 ..< numItems).map({Dummy($0)}))
        
        measure {
            var copy = original
            
            copy.append(Dummy(numItems))
            
            XCTAssertEqual(copy.count, numItems + 1)
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

    static var allTests = [
    ("testCreateValueType", testCreateValueType),
    ("testCreateReferenceType", testCreateReferenceType),
    ("testDeepCopyValueType", testDeepCopyValueType),
    ("testDeepCopyReferenceType", testDeepCopyReferenceType),
    ("testRemoveFirstValueType", testRemoveFirstValueType),
    ("testAlternatingAppendAndRemove", testAlternatingAppendAndRemove),
    ]
}

