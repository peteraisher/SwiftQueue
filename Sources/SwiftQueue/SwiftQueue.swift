public struct SwiftQueue<T> {
    
    @usableFromInline
    internal class Box {
        
        @usableFromInline
        var next: Box?
        
        @usableFromInline
        var element: T
        
        @usableFromInline
        init(_ element: T) {
            self.element = element
        }
    }
    
    public init() {}
    
    @usableFromInline
    internal var start: Box? = nil
    
    @usableFromInline
    internal var end: Box? = nil
    
    @usableFromInline
    internal var totalBoxCount: Int = 0
    
    @usableFromInline
    internal var startBoxCount: Int = 0
}

extension SwiftQueue: Sequence {
    
    public struct Iterator: IteratorProtocol {
        public typealias Element = T
        
        @usableFromInline
        internal var nextBox: Box? = nil
        
        @inlinable
        internal init(_ start: Box?) {
            self.nextBox = start
        }
        
        @inlinable
        mutating public func next() -> T? {
            defer { nextBox = nextBox?.next }
            return nextBox?.element
        }
        
    }
    
    @inlinable
    public func makeIterator() -> SwiftQueue<T>.Iterator {
        return Iterator(start)
    }
}

extension SwiftQueue: Collection {
    
    public typealias Element = T
    
    public struct Index: Comparable {
        public static func == (lhs: SwiftQueue<T>.Index, rhs: SwiftQueue<T>.Index) -> Bool {
            return lhs.index == rhs.index
        }
        
        public static func < (lhs: SwiftQueue<T>.Index, rhs: SwiftQueue<T>.Index) -> Bool {
            return lhs.index < rhs.index
        }
        
        @usableFromInline
        internal let index: Int
        
        @usableFromInline
        internal let box: Unmanaged<Box>?
        
        @inlinable
        init(_ box: Box?, count: Int) {
            index = count
            guard let b = box else {
                self.box = nil
                return
            }
            self.box = Unmanaged<Box>.passUnretained(b)
        }
    }
    
    @inlinable
    public var count: Int { return totalBoxCount - startBoxCount }
    
    @inlinable
    public var startIndex: SwiftQueue<T>.Index {
        return Index(start, count: startBoxCount)
    }
    
    @inlinable
    public var endIndex: SwiftQueue<T>.Index {
        return Index(end, count: totalBoxCount)
    }
    
    @inlinable
    internal func checkIndex(_ index: Index) -> Unmanaged<Box> {
        guard index.index >= startBoxCount && index.index < totalBoxCount else {
            fatalError("Index out of range")
        }
        guard let box = index.box else {
            fatalError("Invalid index")
        }
        return box
    }
    
    @inlinable
    public subscript(position: SwiftQueue<T>.Index) -> T {
        get {
            return checkIndex(position).takeUnretainedValue().element
        }
        mutating set {
            checkIndex(position).takeUnretainedValue().element = newValue
        }
    }
    
    @inlinable
    public func index(after i: SwiftQueue<T>.Index) -> SwiftQueue<T>.Index {
        guard let box = i.box else { return Index(nil, count: i.index + 1) }
        return Index(box.takeUnretainedValue().next, count: i.index + 1)
    }
}

extension SwiftQueue: RangeReplaceableCollection {
    public typealias SubSequence = SwiftQueue
    
    mutating public func append(_ newElement: __owned T) {
        
        totalBoxCount += 1
        
        let newBox = Box(newElement)
        
        guard let oldEnd = end else {
            start = newBox
            end = newBox
            return
        }
        
        oldEnd.next = newBox
        end = newBox
    }
    
    @inlinable
    mutating public func removeFirst() -> T {
        guard let oldStart = start else {
            fatalError("removeFirst() called on empty collection")
        }
        startBoxCount += 1
        let newStart = oldStart.next
        if newStart == nil {
            end = nil
        }
        start = newStart
        return oldStart.element
    }
    
    @inlinable
    mutating public func insert(_ newElement: __owned T, at i: SwiftQueue<T>.Index) {
        let currentBox = checkIndex(i).takeUnretainedValue()
        
        let movedBox = Box(currentBox.element)
        
        movedBox.next = currentBox.next
        currentBox.next = movedBox
        currentBox.element = newElement
        
        totalBoxCount += 1
    }
    
    @inlinable
    mutating public func insert<C>(contentsOf newElements: __owned C, at i: SwiftQueue<T>.Index) where C : Collection, SwiftQueue<T>.Element == C.Element {
        
        let newCount = newElements.count
        
        guard newCount > 0 else { return }
        
        guard newCount > 1 else {
            self.insert(newElements.first!, at: i)
            return
        }
        
        let queueToInsert = SwiftQueue(newElements)
        
        let currentBox = checkIndex(i).takeUnretainedValue()
        
        let movedBox = Box(currentBox.element)
        
        movedBox.next = currentBox.next
        
        let insertQueueStartBox = queueToInsert.start!
        
        currentBox.element = insertQueueStartBox.element
        currentBox.next = insertQueueStartBox.next
        
        let insertQueueEndBox = queueToInsert.end!
        
        insertQueueEndBox.next = movedBox
        
        totalBoxCount += newCount
        
    }
    
    @inlinable
    public init<S>(_ elements: S) where S : Sequence, SwiftQueue.Element == S.Element {
        self.init()
        for element in elements {
            self.append(element)
        }
    }
    
    @inlinable
    public init(repeating repeatedValue: Self.Element, count: Int) {
        self.init()
        for _ in 0 ..< count {
            self.append(repeatedValue)
        }
    }
    
    @inlinable
    public var first: T? { return start?.element }
}

extension SwiftQueue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = T
    
    public init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}
