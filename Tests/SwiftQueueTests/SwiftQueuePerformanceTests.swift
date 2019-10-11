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

    static var allTests = [
    ("testCreateValueType", testCreateValueType),
    ("testCreateReferenceType", testCreateReferenceType),
    ]
}

