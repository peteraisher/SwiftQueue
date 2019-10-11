@usableFromInline
internal final class QueueStorage<T> {
    
    @usableFromInline
    internal class Box {
        
        @usableFromInline
        var next: Box?
        
        @usableFromInline
        var element: T
        
        @usableFromInline
        init?(_ element: T?) {
            guard let theElement = element else { return nil }
            
            self.element = theElement
        }
    }
    
    @usableFromInline
    required internal init() {}
    
    @usableFromInline
    internal var start: Box? = nil
    
    @usableFromInline
    internal var end: Box? = nil
    
    @usableFromInline
    internal var totalBoxCount: Int = 0
    
    @usableFromInline
    internal var startBoxCount: Int = 0
}

extension QueueStorage {
    
    @usableFromInline
    typealias Index = SwiftQueue<T>.Index
    
    @inlinable
    public var count: Int { return totalBoxCount - startBoxCount }
    
    @inlinable
    public var startIndex: SwiftQueue<T>.Index {
        return SwiftQueue<T>.Index(start, count: startBoxCount)
    }
    
    @inlinable
    public var endIndex: SwiftQueue<T>.Index {
        return SwiftQueue<T>.Index(end, count: totalBoxCount)
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
        set {
            checkIndex(position).takeUnretainedValue().element = newValue
        }
    }
    
    @inlinable
    public func index(after i: SwiftQueue<T>.Index) -> SwiftQueue<T>.Index {
        guard let box = i.box else { return Index(nil, count: i.index + 1) }
        return Index(box.takeUnretainedValue().next, count: i.index + 1)
    }
}

extension QueueStorage {
    
    public func append(_ newElement: __owned T) {
        
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
    public func removeFirst() -> T {
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
    public func insert(_ newElement: __owned T, at i: SwiftQueue<T>.Index) {
        let currentBox = checkIndex(i).takeUnretainedValue()
        
        let movedBox = Box(currentBox.element)!
        
        movedBox.next = currentBox.next
        currentBox.next = movedBox
        currentBox.element = newElement
        
        totalBoxCount += 1
    }
    
    @inlinable
    public func insert<C>(contentsOf newElements: __owned C, at i: SwiftQueue<T>.Index) where C : Collection, SwiftQueue<T>.Element == C.Element {
        
        let newCount = newElements.count
        
        guard newCount > 0 else { return }
        
        guard newCount > 1 else {
            self.insert(newElements.first!, at: i)
            return
        }
        
        let queueToInsert = QueueStorage(newElements)
        
        let currentBox = checkIndex(i).takeUnretainedValue()
        
        let movedBox = Box(currentBox.element)!
        
        movedBox.next = currentBox.next
        
        let insertQueueStartBox = queueToInsert.start!
        
        currentBox.element = insertQueueStartBox.element
        currentBox.next = insertQueueStartBox.next
        
        let insertQueueEndBox = queueToInsert.end!
        
        insertQueueEndBox.next = movedBox
        
        totalBoxCount += newCount
        
    }
    
    @inlinable
    public convenience init<S>(_ elements: S) where S : Sequence, T == S.Element {
        self.init()
        for element in elements {
            self.append(element)
        }
    }
    
    @inlinable
    public convenience init(repeating repeatedValue: T, count: Int) {
        self.init()
        for _ in 0 ..< count {
            self.append(repeatedValue)
        }
    }
    
    @inlinable
    public var first: T? { return start?.element }
}

extension QueueStorage: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = T
    
    public convenience init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}

extension QueueStorage {
    
    @inlinable
    internal convenience init(copying other: QueueStorage<T>) {
        self.init()
        self.startBoxCount = other.startBoxCount
        self.totalBoxCount = other.totalBoxCount
        
        guard other.count > 0 else { return }
        
        self.start = Box(other.start!.element)
        var thisBox = self.start!
        var otherBox = other.start?.next
        while otherBox != nil {
            thisBox.next = Box(otherBox?.element)
            otherBox = otherBox?.next
            guard let nextBox = thisBox.next else { break }
            thisBox = nextBox
        }
        self.end = thisBox
    }
    
    @inlinable
    internal func copy() -> QueueStorage {
        return QueueStorage(copying: self)
    }
}
