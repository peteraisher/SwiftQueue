public struct SwiftQueue<Element>: Sequence, Collection, RangeReplaceableCollection {
    @usableFromInline
    internal var storage: QueueStorage<Element>
}

extension SwiftQueue {
    @usableFromInline
    mutating internal func copyStorage() {
        storage = storage.copy()
    }
    
    @usableFromInline
    mutating internal func checkStorageUniqueAndCopyIfNecessary() {
        if !isKnownUniquelyReferenced(&storage) {
            copyStorage()
        }
    }
}

// MARK: - Sequence

// MARK: Iterating

extension SwiftQueue {

    @usableFromInline
    typealias Box = QueueStorage<Element>.Box
    
    public struct Iterator: IteratorProtocol {
        
        @usableFromInline
        internal var nextBox: Box? = nil
        
        @inlinable
        internal init(_ start: Box?) {
            self.nextBox = start
        }
        
        @inlinable
        mutating public func next() -> Element? {
            defer { nextBox = nextBox?.next }
            return nextBox?.element
        }
        
    }
    
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(storage.start)
    }
}

// MARK: - Collection

// MARK: Associated Types

extension SwiftQueue {
//    public typealias Index = Int
    public struct Index: Comparable {
        @inlinable
        public static func < (lhs: SwiftQueue<Element>.Index, rhs: SwiftQueue<Element>.Index) -> Bool {
            return lhs.offset < rhs.offset
        }
        
        @inlinable
        public static func == (lhs: SwiftQueue<Element>.Index, rhs: SwiftQueue<Element>.Index) -> Bool {
            return lhs.offset == rhs.offset
        }
        
        @usableFromInline
        internal var offset: Int
        
        @usableFromInline
        internal var box: Unmanaged<Box>?
        
        @inlinable
        init(_ box: Box?, offset: Int) {
            self.offset = offset
            self.box = box.map{Unmanaged.passUnretained($0)}
        }
    }
    
    public typealias SubSequence = SwiftQueue
}

// MARK: Accessing Elements

extension SwiftQueue {
    
    @inlinable
    public subscript(position: Index) -> Element {
        get {
            storage.checkIndex(position)
            return storage.getElementAtUncheckedIndex(position)
        }
        mutating set {
            storage.checkIndex(position)
            storage.setElementAtUncheckedIndex(position, to: newValue)
        }
    }
}
// MARK: Selecting and excluding elements
extension SwiftQueue {
    
    @inlinable
    mutating public func popFirst() -> Element? {
        checkStorageUniqueAndCopyIfNecessary()
        return storage.popFirst()
    }
    
    @inlinable
    mutating public func removeFirst() -> Element {
        checkStorageUniqueAndCopyIfNecessary()
        return storage.removeFirst()
    }
    
    @inlinable
    mutating public func removeFirst(_ k: Int) {
        guard k > 0 else { return }
        checkStorageUniqueAndCopyIfNecessary()
        storage.removeFirst(k)
    }

// MARK: Manipulating indices

    
    @inlinable
    public var startIndex: Index { Index(storage.start, offset: 0) }
    
    @inlinable
    public var endIndex: Index { Index(storage.end, offset: count) }
    
    @inlinable
    public func index(after i: Index) -> Index {
        return storage.index(after: i)
    }
    
    @inlinable
    public func formIndex(after i: inout Index) {
        storage.formIndex(after: &i)
    }
}

// MARK: Instance Properties

extension SwiftQueue {
    
    @inlinable
    public var count: Int { return storage.count }
    
    @inlinable
    public var first: Element? { return storage.first }
    
    @inlinable
    public var isEmpty: Bool { return storage.start == nil }
    
}

// MARK: - RangeReplaceableCollection

// MARK: Initializers

extension SwiftQueue {
    
    @inlinable
    public init() {
        self.storage = QueueStorage<Element>()
    }
    
    @inlinable
    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.storage = QueueStorage(elements)
    }
    
    @inlinable
    public init(repeating repeatedValue: Element, count: Int) {
        self.storage = QueueStorage(repeating: repeatedValue, count: count)
    }
    
}

// MARK: Instance methods

extension SwiftQueue {
    
    @inlinable
    mutating public func append(_ newElement: __owned Element) {
        checkStorageUniqueAndCopyIfNecessary()
        storage.append(newElement)
    }
    
    @inlinable
    mutating public func insert(_ newElement: __owned Element, at i: Index) {
        checkStorageUniqueAndCopyIfNecessary()
        storage.insert(newElement, at: i)
    }
    
    @inlinable
    mutating public func insert<C>(contentsOf newElements: __owned C, at i: Index) where C : Collection, Element == C.Element {
        guard newElements.count > 0 else { return }
        checkStorageUniqueAndCopyIfNecessary()
        storage.insert(contentsOf: newElements, at: i)
    }
    
    @inlinable
    mutating public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        storage = QueueStorage()
    }
}


// MARK: - ExpressibleByArrayLiteral

extension SwiftQueue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

// MARK: - Extra methods

extension SwiftQueue {
    @inlinable
    public var last: Element? { return storage.last }
}
