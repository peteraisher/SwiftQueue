public struct SwiftQueue<T> {
    @usableFromInline
    internal var storage: QueueStorage<T>
}

extension SwiftQueue: Sequence {
    
    public struct Iterator: IteratorProtocol {
        public typealias Element = T
        
        @usableFromInline
        internal var nextBox: QueueStorage<T>.Box? = nil
        
        @inlinable
        internal init(_ start: QueueStorage<T>.Box?) {
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
        return Iterator(storage.start)
    }
}

extension SwiftQueue: Collection {
    
    public typealias Element = T

    @usableFromInline
    typealias Box = QueueStorage<T>.Box
    
    public struct Index: Comparable {
        
        @inlinable
        public static func == (lhs: SwiftQueue<T>.Index, rhs: SwiftQueue<T>.Index) -> Bool {
            return lhs.index == rhs.index
        }
        
        @inlinable
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
    public var count: Int { return storage.totalBoxCount - storage.startBoxCount }
    
    @inlinable
    public var startIndex: SwiftQueue<T>.Index {
        return Index(storage.start, count: storage.startBoxCount)
    }
    
    @inlinable
    public var endIndex: SwiftQueue<T>.Index {
        return Index(storage.end, count: storage.totalBoxCount)
    }
    
    @inlinable
    internal func checkIndex(_ index: Index) -> Unmanaged<Box> {
        guard index.index >= storage.startBoxCount && index.index < storage.totalBoxCount else {
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
        return storage.index(after: i)
    }
}

extension SwiftQueue: RangeReplaceableCollection {
    
    public init() {
        self.storage = QueueStorage<T>()
    }
    
    public typealias SubSequence = SwiftQueue
    
    @usableFromInline
    mutating internal func copyStorage() {
        storage = storage.copy()
    }
    
    @usableFromInline
    mutating func checkUniqueAndCopyIfNecessary() {
        if !isKnownUniquelyReferenced(&storage) {
            copyStorage()
        }
    }
    
    mutating public func append(_ newElement: __owned T) {
        checkUniqueAndCopyIfNecessary()
        storage.append(newElement)
    }
    
    @inlinable
    mutating public func removeFirst() -> T {
        checkUniqueAndCopyIfNecessary()
        return storage.removeFirst()
    }
    
    @inlinable
    mutating public func insert(_ newElement: __owned T, at i: SwiftQueue<T>.Index) {
        checkUniqueAndCopyIfNecessary()
        storage.insert(newElement, at: i)
    }
    
    @inlinable
    mutating public func insert<C>(contentsOf newElements: __owned C, at i: SwiftQueue<T>.Index) where C : Collection, SwiftQueue<T>.Element == C.Element {
        guard newElements.count > 0 else { return }
        checkUniqueAndCopyIfNecessary()
        storage.insert(contentsOf: newElements, at: i)
    }
    
    @inlinable
    public init<S>(_ elements: S) where S : Sequence, SwiftQueue.Element == S.Element {
        self.storage = QueueStorage(elements)
    }
    
    @inlinable
    public init(repeating repeatedValue: Self.Element, count: Int) {
        self.storage = QueueStorage(repeating: repeatedValue, count: count)
    }
    
    @inlinable
    public var first: T? { return storage.first }
}

extension SwiftQueue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = T
    
    public init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}
