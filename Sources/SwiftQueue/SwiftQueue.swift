public struct SwiftQueue<Element>: Sequence, Collection, RangeReplaceableCollection {
    @usableFromInline
    internal var storage: ContiguousArray<Element?>
    
    @usableFromInline
    internal var firstStorageIndex: Int = 0
}

//extension SwiftQueue {
//    @usableFromInline
//    mutating internal func copyStorage() {
//        storage = storage.copy()
//    }
//
//    @usableFromInline
//    mutating internal func checkStorageUniqueAndCopyIfNecessary() {
//        if !isKnownUniquelyReferenced(&storage) {
//            copyStorage()
//        }
//    }
//}

// MARK: - Sequence

// MARK: Iterating

extension SwiftQueue {

//    @usableFromInline
//    typealias Box = QueueStorage<Element>.Box
    
    public struct Iterator: IteratorProtocol {
        
        @usableFromInline
        internal var arraySliceIterator: ArraySlice<Element?>.Iterator
        
        @inlinable
        internal init(storage: ContiguousArray<Element?>, _ start: Int) {
            self.arraySliceIterator = storage[start...].makeIterator()
        }
        
        @inlinable
        mutating public func next() -> Element? {
            return arraySliceIterator.next().map({$0!})
        }
        
    }
    
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(storage: storage, firstStorageIndex)
    }
}

// MARK: - Collection

// MARK: Associated Types

extension SwiftQueue {
    public typealias Index = Int
    
    public typealias SubSequence = SwiftQueue
}

// MARK: Accessing Elements

extension SwiftQueue {
    
    @inlinable
    public subscript(position: Index) -> Element {
        get {
            return storage[position + firstStorageIndex]!
        }
        mutating set {
            storage[position + firstStorageIndex] = newValue
        }
    }
}
// MARK: Selecting and excluding elements
extension SwiftQueue {
    
    @inlinable
    mutating internal func resize() {
        let newStorage = ContiguousArray<Element?>.init(unsafeUninitializedCapacity: storage.capacity/2) { (bufferPointer, initializedCount) in
            (_, initializedCount) = bufferPointer.initialize(from: storage[firstStorageIndex...])
        }
        storage = newStorage
        firstStorageIndex = 0
    }
    
    @inlinable
    mutating internal func resizeIfNecessary() {
        if firstStorageIndex * 3 > 2 * storage.capacity {
            resize()
        }
    }
    
    @inlinable
    mutating public func popFirst() -> Element? {
        guard firstStorageIndex < storage.count else { return nil }
        return removeFirst()
    }
    
    @inlinable
    mutating public func removeFirst() -> Element {
        defer {
            storage[firstStorageIndex] = nil
            firstStorageIndex += 1
            resizeIfNecessary()
        }
        return storage[firstStorageIndex]!
    }
    
    @inlinable
    mutating public func removeFirst(_ k: Int) {
        guard k > 0 else { return }
        for i in firstStorageIndex ..< firstStorageIndex + k {
            storage[i] = nil
        }
        firstStorageIndex += k
        resizeIfNecessary()
    }

// MARK: Manipulating indices

    
    @inlinable
    public var startIndex: Index { 0 }
    
    @inlinable
    public var endIndex: Index { count }
    
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
    public var count: Int { return storage.count - firstStorageIndex }
    
    @inlinable
    public var first: Element? {
        guard storage.count > firstStorageIndex else { return nil }
        return storage[firstStorageIndex]!
    }
    
    @inlinable
    public var isEmpty: Bool { return storage.count == firstStorageIndex }
    
}

// MARK: - RangeReplaceableCollection

// MARK: Initializers

extension SwiftQueue {
    
    @inlinable
    public init() {
        self.storage = ContiguousArray<Element?>()
    }
    
    @inlinable
    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.storage = ContiguousArray(elements.map({Optional($0)}))
    }
    
    @inlinable
    public init(repeating repeatedValue: Element, count: Int) {
        self.storage = ContiguousArray(repeating: Optional(repeatedValue), count: count)
    }
    
}

// MARK: Instance methods

extension SwiftQueue {
    
    @inlinable
    mutating public func append(_ newElement: __owned Element) {
        storage.append(newElement)
    }
    
    @inlinable
    mutating public func insert(_ newElement: __owned Element, at i: Index) {
        storage.insert(newElement, at: i + firstStorageIndex)
    }
    
    @inlinable
    mutating public func insert<C>(contentsOf newElements: __owned C, at i: Index) where C : Collection, Element == C.Element {
        guard newElements.count > 0 else { return }
        storage.insert(contentsOf: newElements.map({Optional($0)}), at: i + firstStorageIndex)
    }
    
    @inlinable
    mutating public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        storage.removeAll(keepingCapacity: keepCapacity)
        firstStorageIndex = 0
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
    public var last: Element? {
        guard storage.count > firstStorageIndex else { return nil }
        return storage.last!
    }
}
