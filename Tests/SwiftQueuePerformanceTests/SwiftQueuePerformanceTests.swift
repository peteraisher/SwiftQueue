import XCTest
@testable import SwiftQueue

final class SwiftQueuePerformanceTests: XCTestCase {
    
    let numItems: Int = 10_000
    let numRepeats: Int = 100
    
    final class Dummy: Equatable {
        let number: Int
        init(_ number: Int) { self.number = number }
        static func == (lhs: Dummy, rhs: Dummy) -> Bool {
            return lhs.number == rhs.number
        }
    }
    
    func testCreateValueType() {
        
        let items = Array(0 ..< numItems)
        
        measure {
            for _ in 0 ..< 100 * numRepeats {
                let queue = SwiftQueue(items)
                _fixLifetime(queue)
            }
        }
        
    }
    
    func testCreateReferenceType() {
        
        let items = Array((0 ..< 10 * numItems).map({Dummy($0)}))
        
        measure {
            for _ in 0 ..< numRepeats {
                let queue = SwiftQueue(items)
                _fixLifetime(queue)
            }
        }
    }
    
    func testDeepCopyValueType() {
        let original = SwiftQueue(0 ..< numItems)
        
        measure {
            for _ in 0 ..< 100 * numRepeats {
                var copy = original
                copy.append(numItems)
                _fixLifetime(copy)
            }
        }
    }
    
    func testDeepCopyReferenceType() {
        let original = SwiftQueue((0 ..< numItems).map({Dummy($0)}))
        
        measure {
            for _ in 0 ..< 10 * numRepeats {
                var copy = original
                copy.append(Dummy(numItems))
                _fixLifetime(copy)
            }
        }
    }
    
    func testRemoveFirstValueType() {
        
        let elements = Array(0 ..< numItems)
        
        measure {
            for _ in 0 ..< numRepeats {
                var original = SwiftQueue(elements)
                for _ in 0 ..< numItems {
                    _ = original.removeFirst()
                }
                _fixLifetime(original)
            }
        }
    }
    
    func testAlternatingAppendAndRemove() {
        measure {
            for _ in 0 ..< numRepeats {
                var queue = SwiftQueue<Int>()
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
    }
    
    
    func testRandomModifications() {
        func randomIndex(count: Int) -> Int {
            return Int(drand48() * Double(count))
        }
        func randomValue() -> Int {
            return Int(drand48() * Double(Int.max))
        }
        func randomAction(queue: inout SwiftQueue<Int>) {
            switch randomIndex(count: 60) {
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
            srand48(102382034)
            for _ in 0 ..< 10 * numRepeats {
                var queue = SwiftQueue( 0 ..< 10 )
                for _ in 0 ..< 100 {
                    switch randomIndex(count: 100) {
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

