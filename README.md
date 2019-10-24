# SwiftQueue

A first-in-first-out queue.

The `SwiftQueue` type stores its elements in a circular buffer in one or two contiguous
regions of memory. Add elements to the queue by calling `append(_:)` and remove elements
in the order they were added by calling `removeFirst()` on a non-empty queue or `popFirst()`
on a possibly-empty queue.

Subscript access allows access to the elements of the queue in the order that they were added.

## Features

- Conforms to the same protocols as `Array` including `Collection` and `RangeReplaceableCollection`.
- Uses a highly-performant circular buffer backing.
- `append(_:)` and `popFirst()` are both O(*1*) operations.
- Significantly better cache-locality than linked-list implementations.
- Thoroughly documented source code.

## Documentation

The source code contains extensive documentation of both public and internal functions.
`SwiftQueue` does not add extra methods for `push(_:)`, `pop()` and `peek()` instead using
the existing methods and properties defined in Swift's various protocols:
- `append(_:)` to add an element to the end of the queue
- `popFirst() -> Element?` to remove the first element in the queue or return `nil` if empty
- `first: Element?` to access the first element in the queue without removing it.

### Initialization

`SwiftQueue` can be initialized just like an `Array` instance.

A queue with `Int` elements can be created as follows:

```swift
var queue = SwiftQueue<Int>()
...
var queue = SwiftQueue([1, 3, 5, 8, 9])
...
var queue = SwiftQueue( 2 ..< 14 )
...
var queue: SwiftQueue = [1, 2, 4, 3, 6]
```

### Adding, removing, and accessing elements

Elements can be added, removed and accessed using standard methods and properties:

```swift
var queue: SwiftQueue = ["I", "love", "to", "queue"]

queue.append("!")           // queue is now ["I", "love", "to", "queue", "!"]
print(queue.removeFirst())  // prints "I"
                            // queue is now ["love", "to", "queue", "!"]

print(queue.first!)         // prints "love"

for element in queue {
    print(element)          // prints "to", "queue", "!"
}

print(queue[1])             // prints "queue"

while let element = queue.popFirst() {
    print(element)          // prints "to", "queue", "!"
}

print(queue.isEmpty)        // prints "true"
```

### Other operations

Other methods and properties can be used like with `Array`:

```swift
let queue: SwiftQueue = [1.0, 3.2, 3.5, 8.0]

queue.count             // returns 4

queue.last              // returns Optional(8.0)
```
## Performance

For operations such as `append(_:)`, performance of `SwiftQueue` is similar to `Array`.
The operations `removeFirst()` and `removeFirst(k)` have complexity O(*1*) and O(*k*)
respectively, instead of O(*n*), where *n* is the length of the collection. Additionally, when the
number of calls to `append(_:)` and `removeFirst()` are balanced and the length of the
queue remains stable, memory locality is maintained, thereby improving cache performance.
