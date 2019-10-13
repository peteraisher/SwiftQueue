# SwiftQueue

A first-in-first-out queue.

The `SwiftQueue` type stores its elements in a circular buffer in one or two contiguous
regions of memory. Add elements to the queue by calling `append(_:)` and remove elements
in the order they were added by calling `removeFirst()` on a non-empty queue or `popFirst()`
on a possibly-empty queue.

Subscript access allows access to the elements of the queue in the order that they were added.

## Usage example

    var emptyQueue = SwiftQueue<Int>()
    
    emptyQueue.isEmpty      // returns true
    emptyQueue.first        // returns nil
    
    var oneToTen = SwiftQueue( 1 ... 10 )
    
    oneToTen.count          // returns 10
    oneToTen.removeFirst()  // returns 1
    oneToTen.first!         // returns 2
    oneToTen.last!          // returns 10
    oneToTen.count          // returns 9
    
    oneToTen.append(15)
    
    oneToTen.count          // returns 10
    oneToTen.last!          // returns 15
    
## Performance

For operations such as `append(_:)`, performance of `SwiftQueue` is similar to `Array`.
The operations `removeFirst()` and `removeFirst(k)` have complexity O(*1*) and O(*k*)
respectively, instead of O(*n*), where *n* is the length of the collection. Additionally, when the
number of calls to `append(_:)` and `removeFirst()` are balanced and the length of the
queue remains stable, memory locality is maintained, thereby improving cache performance.
