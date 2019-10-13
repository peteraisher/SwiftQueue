import Foundation

public struct SwiftQueue<Element>: Sequence, Collection, RangeReplaceableCollection {
    
    @usableFromInline
    internal typealias _Backing = _Buffer<Element>
    
    /// The buffer backing this queue
    @usableFromInline
    internal var _buffer: _Backing
}

// MARK: - Sequence

// MARK: Iterating

extension SwiftQueue {
    
    
    public struct Iterator: IteratorProtocol {
        public mutating func next() -> Element? {
            return bufferIterator.next()
        }
        
        @usableFromInline
        var bufferIterator: _Backing.Iterator
        
        @inlinable
        init(_ buffer: _Backing) {
            bufferIterator = buffer.makeIterator()
        }
    }
//    typealias Iterator = _Backing.Iterator
    
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(_buffer)
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
    internal mutating func _makeUnique() {
      if _slowPath(!_buffer.isUniquelyReferenced()) {
        _buffer = _Backing(copying: _buffer)
      }
    }
    
    @inlinable
    internal func _checkIndex(_ index: Int) {
        assert(index >= 0 && index < count)
    }
    
    @inlinable
    public subscript(index: Int) -> Element {
      get {
        _checkIndex(index)
        return _buffer.getCircularElementAtUncheckedIndex(index)
      }
      _modify {
        _makeUniqueAndLogicallyReorderIfNotUnique()
        _checkIndex(index)
        let address = _buffer.getCircularElementPointerAtUncheckedIndex(index)
        yield &address.pointee
      }
    }
}
// MARK: Selecting and excluding elements
extension SwiftQueue {
    
    @inlinable
    @discardableResult
    mutating public func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    @inlinable
    mutating func _makeUniqueAndLogicallyReorderIfNotUnique() {
        if _slowPath(!_buffer.isUniquelyReferenced()) {
            _buffer = _buffer._createLogicallyOrderedCopy()
        }
    }
    
    @inlinable
    @discardableResult
    internal mutating func _removeFirstAssumingUnique() -> Element {
        let headIndex = _buffer.headIndex
        let headPointer = _buffer.firstElementAddress + headIndex
        let result = headPointer.move()
        _buffer.headIndex = headIndex + 1
        return result
    }
    
    @inlinable
    mutating public func removeFirst() -> Element {
        _makeUniqueAndLogicallyReorderIfNotUnique()
        return _removeFirstAssumingUnique()
    }
    
    @inlinable
    mutating public func removeFirst(_ k: Int) {
        guard k > 0 else { return }
        _makeUniqueAndLogicallyReorderIfNotUnique()
        for _ in 0 ..< k {
            _removeFirstAssumingUnique()
        }
    }
}
// MARK: Manipulating indices
    
extension SwiftQueue {
    
    @inlinable
    public var startIndex: Int { 0 }
    
    @inlinable
    public var endIndex: Int { count }
    
    @inlinable
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    @inlinable
    public func formIndex(after i: inout Int) {
        i += 1
    }
}

// MARK: Instance Properties

extension SwiftQueue {
    
    @inlinable
    public var count: Int { return _getCount() }
    
    @inlinable
    public var first: Element? {
        guard !isEmpty else { return nil }
        return self[0]
    }
    
    @inlinable
    public var isEmpty: Bool { return _buffer.isEmpty }
    
}

// MARK: - RangeReplaceableCollection

// MARK: Initializers

extension SwiftQueue {
    
    @inlinable
    public init() {
        self._buffer = _Buffer<Element>()
    }
    
    @inlinable
    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self._buffer = _copySequenceToContiguousBuffer(elements)
    }
    
    @inlinable
    public init(repeating repeatedValue: Element, count: Int) {
        self._buffer = _Backing.init(_uninitializedCount: count, minimumCapacity: 0)
        _buffer.firstElementAddress.initialize(repeating: repeatedValue, count: count)
        _buffer.tailIndex = count
    }
}

// MARK: Instance methods

extension SwiftQueue {
    
    @inlinable
    internal func _getCount() -> Int { return _buffer.count }
    
    /// Copy the contents of the current buffer to a new unique mutable buffer.
    /// The count of the new buffer is set to `oldCount`, the capacity of the
    /// new buffer is big enough to hold 'oldCount' + 1 elements.
    @inline(never)
    @inlinable // @specializable
    internal mutating func _copyToNewBuffer(oldCount: Int) {
        let newCount = oldCount + 1
        var newBuffer = _buffer._forceCreateUniqueMutableBuffer(newCount: oldCount, requiredCapacity: newCount)
        _buffer._reorderingOutOfPlaceUpdate(
            dest: &newBuffer,
            headCount: oldCount,
            newCount: 0)
    }
    
    @inlinable
    internal mutating func _reserveCapacityAssumingUniqueBuffer(oldCount: Int) {
        if _slowPath(oldCount + 1 > _buffer.capacity) {
            _copyToNewBuffer(oldCount: oldCount)
        }
    }
    
    @inlinable
    internal mutating func _makeUniqueAndReserveCapacityIfNotUnique() {
        if _slowPath(!_buffer.isUniquelyReferenced()) {
            _copyToNewBuffer(oldCount: _buffer.count)
        }
    }
    
    @inlinable
    internal mutating func _appendElementAssumeUniqueAndCapacity(
        _ oldTailIndex: Int,
        newElement: __owned Element
    ) {
        _buffer.tailIndex = oldTailIndex + 1
        (_buffer.firstElementAddress + oldTailIndex).initialize(to: newElement)
    }
    
    @inlinable
    mutating public func append(_ newElement: __owned Element) {
        _makeUniqueAndReserveCapacityIfNotUnique()
        let oldCount = _getCount()
        _reserveCapacityAssumingUniqueBuffer(oldCount: oldCount)
        let oldTailIndex = _buffer.tailIndex
        _appendElementAssumeUniqueAndCapacity(oldTailIndex, newElement: newElement)
    }
    
    @inlinable
    mutating public func insert(_ newElement: __owned Element, at i: Index) {
        _buffer._reorderingOutOfPlaceReplace(circularRange: i ..< i, with: CollectionOfOne(newElement), count: 1)
    }
    
    @inlinable
    mutating public func insert<C>(contentsOf newElements: __owned C, at i: Index) where C : Collection, Element == C.Element {
        guard newElements.count > 0 else { return }
        _buffer._reorderingOutOfPlaceReplace(circularRange: i ..< i, with: newElements, count: newElements.count)
//        storage.insert(contentsOf: newElements.map({Optional($0)}), at: i + firstStorageIndex)
    }
    
    @inlinable
    mutating public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        if keepCapacity && !isEmpty && _buffer.isUniquelyReferenced() {
            let _elementPointer = _buffer.firstElementAddress
            if _buffer.tailIndexIsWrapped {
                // deinit from headIndex to capacity
                (_elementPointer + _buffer.headIndex).deinitialize(count: _buffer.capacity - _buffer.headIndex)
                // deinit up to tailIndex
                _elementPointer.deinitialize(count: _buffer.tailIndex)
            } else {
                (_elementPointer + _buffer.headIndex).deinitialize(count: _buffer.tailIndex - _buffer.headIndex)
            }
            _buffer.headIndex = 0
            _buffer.tailIndex = 0
            _buffer.tailIndexIsWrapped = false
        } else {
            _buffer = _Backing()
        }
//        storage.removeAll(keepingCapacity: keepCapacity)
//        firstStorageIndex = 0
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
        let theCount = count
        guard theCount > 0 else { return nil }
        return self[theCount - 1]
//        guard storage.count > firstStorageIndex else { return nil }
//        return storage.last!
    }
}
