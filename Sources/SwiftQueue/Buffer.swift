@usableFromInline
internal class _StorageBase {
    @usableFromInline
    final var capacityIndicesAndFlag = _CircularArrayBody()
    
    @usableFromInline
    var _rawPointer: UnsafeMutableRawPointer
    
    @inlinable
    init() {
        _rawPointer = UnsafeMutableRawPointer(&capacityIndicesAndFlag)
    }
}

@inlinable
internal func _growArrayCapacity(_ capacity: Int) -> Int {
    return capacity * 2
}

@usableFromInline
internal class _EmptyStorage: _StorageBase {
}

@usableFromInline
struct _CircularArrayBody {
    @usableFromInline
    var capacity: Int
    @usableFromInline
    var headIndex: Int
    @usableFromInline
    var tailIndexAndFlag: UInt
    
    @inlinable
    var tailIndexIsWrapped: Bool {
        get {
            return (tailIndexAndFlag & 1) != 0
        }
        set {
            tailIndexAndFlag = newValue ? tailIndexAndFlag | 1 : tailIndexAndFlag & ~1
        }
    }
    
    @inlinable
    var tailIndex: Int {
        get {
            return Int(tailIndexAndFlag &>> 1)
        }
        set {
            if newValue == capacity {
                tailIndexAndFlag = 1
                
            } else {
                tailIndexAndFlag = UInt(truncatingIfNeeded: newValue &<< 1) | (tailIndexAndFlag & 1)
            }
        }
    }
    
    @usableFromInline
    init(count: Int, capacity: Int) {
        self.headIndex = 0
        self.tailIndexAndFlag = (count == capacity) ? 1 : UInt(truncatingIfNeeded: count &<< 1)
        self.capacity = capacity
    }
    
    init() {
        self.headIndex = 0
        self.tailIndexAndFlag = 0
        self.capacity = 0
    }
}

var _emptyArrayStorage: _EmptyStorage = _EmptyStorage()

@usableFromInline
class _Storage<Element>: _StorageBase {
    
    @inlinable
    init(capacity: Int, count: Int) {
        super.init()
        self.capacityIndicesAndFlag = _CircularArrayBody(count: count, capacity: capacity)
        let _elementPointer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        self._rawPointer = UnsafeMutableRawPointer(_elementPointer)
    }
    
    @inlinable
    internal final var _elementPointer: UnsafeMutablePointer<Element> {
        return _rawPointer.assumingMemoryBound(to: Element.self)
    }
    
    
    
    @inlinable
    deinit {
        // we allow tailIndex to wrap beyond capacity such that tailIndex - capacity <= headIndex
        // headIndex < capacity
        if capacityIndicesAndFlag.tailIndexIsWrapped {
            // deinit from headIndex to capacity
            (_elementPointer + capacityIndicesAndFlag.headIndex).deinitialize(count: capacityIndicesAndFlag.capacity - capacityIndicesAndFlag.headIndex)
            // deinit up to tailIndex
            _elementPointer.deinitialize(count: capacityIndicesAndFlag.tailIndex)
        } else {
            (_elementPointer + capacityIndicesAndFlag.headIndex).deinitialize(count: capacityIndicesAndFlag.tailIndex - capacityIndicesAndFlag.headIndex)
        }
        _elementPointer.deallocate()
    }
}

@usableFromInline
struct _Buffer<Element> {
    
    @usableFromInline
    internal var _storage: _StorageBase
    
    @inlinable
    internal var tailIndex: Int {
        get {
            return _storage.capacityIndicesAndFlag.tailIndex
        }
        nonmutating set {
            assert(newValue >= 0)
            assert(newValue <= capacity)
            if _slowPath(newValue == capacity) {
                _storage.capacityIndicesAndFlag.tailIndex = 0
                _storage.capacityIndicesAndFlag.tailIndexIsWrapped = true
            } else {
                _storage.capacityIndicesAndFlag.tailIndex = newValue
            }
        }
    }
    
    @inlinable
    internal var headIndex: Int {
        get {
            return _storage.capacityIndicesAndFlag.headIndex
        }
        nonmutating set {
            assert(newValue >= 0)
            assert(newValue <= capacity)
            if _slowPath(newValue == capacity) {
                _storage.capacityIndicesAndFlag.headIndex = 0
                _storage.capacityIndicesAndFlag.tailIndexIsWrapped = false
            } else {
                _storage.capacityIndicesAndFlag.headIndex = newValue
            }
        }
    }
    
    @inlinable
    internal var tailIndexIsWrapped: Bool {
        get {
            return _storage.capacityIndicesAndFlag.tailIndexIsWrapped
        }
        nonmutating set {
            _storage.capacityIndicesAndFlag.tailIndexIsWrapped = newValue
        }
    }
    
    @usableFromInline
    internal var count: Int {
        return tailIndex - headIndex + (tailIndexIsWrapped ? capacity : 0)
    }
    
    @usableFromInline
    internal var isEmpty: Bool {
        count == 0
    }
    
    @usableFromInline
    internal var capacity: Int { return _storage.capacityIndicesAndFlag.capacity }
    
    @usableFromInline
    internal var firstElementAddress: UnsafeMutablePointer<Element> {
        return _storage._rawPointer.assumingMemoryBound(to: Element.self)
    }
    
    @inlinable
    func _uncheckedLinearIndex(from circularIndex: Int) -> Int {
        return (headIndex + circularIndex) % capacity
    }
    
    @inlinable
    func getCircularElementAtUncheckedIndex(_ index: Int) -> Element {
        let linearIndex = _uncheckedLinearIndex(from: index)
        return self[linearIndex]
    }
    
    @inlinable
    func getCircularElementPointerAtUncheckedIndex(_ index: Int) -> UnsafeMutablePointer<Element> {
        let linearIndex = _uncheckedLinearIndex(from: index)
        return firstElementAddress + linearIndex
    }
    
    @inlinable
    @inline(__always)
    func getElement(i: Int) -> Element {
        return firstElementAddress[i]
    }
    
    @inlinable
    subscript(i: Int) -> Element {
        @inline(__always)
        get {
            return getElement(i: i)
        }
        @inline(__always)
        nonmutating set {
            var nv = newValue
            let tmp = nv
            nv = firstElementAddress[i]
            firstElementAddress[i] = tmp
        }
    }
    
    @inlinable
    internal mutating func isUniquelyReferenced() -> Bool {
        return isKnownUniquelyReferenced(&_storage)
    }
    
    @inlinable
    internal var owner: AnyObject {
      return _storage
    }
    
    @inlinable
    internal init() {
        _storage = _EmptyStorage()
    }
    
    @inlinable
    internal mutating func requestUniqueMutableBackingBuffer(
        minimumCapacity: Int
    ) -> _Buffer<Element>? {
        if _fastPath(isUniquelyReferenced() && capacity >= minimumCapacity) {
            return self
        }
        return nil
    }
    
    /// Make a buffer with uninitialized elements.  After using this
    /// method, you must either initialize the `count` elements at the
    /// result's `.firstElementAddress` or set the result's `.count`
    /// to zero.
    @inlinable
    internal init(
      _uninitializedCount uninitializedCount: Int,
      minimumCapacity: Int
    ) {
        let realMinimumCapacity = Swift.max(uninitializedCount, minimumCapacity)
        if realMinimumCapacity == 0 {
            self = _Buffer<Element>()
        }
        else {
            _storage = _Storage<Element>(capacity: realMinimumCapacity, count: uninitializedCount)
        }
    }
}

@inlinable
internal func _copySequenceToContiguousBuffer<S: Sequence>(_ source: S) -> _Buffer<S.Element> {
    let initialCapacity = source.underestimatedCount
    var builder =
        _UnsafePartiallyInitializedBuffer<S.Element>(
            initialCapacity: initialCapacity)
    
    var iterator = source.makeIterator()
    
    // FIXME(performance): use _copyContents(initializing:).
    // Add elements up to the initial capacity without checking for regrowth.
    for _ in 0..<initialCapacity {
        builder.addWithExistingCapacity(iterator.next()!)
    }
    
    // Add remaining elements, if any.
    while let element = iterator.next() {
        builder.add(element)
    }
    
    return builder.finish()
}

/// A "builder" interface for initializing buffers.
///
/// This presents a "builder" interface for initializing a buffer
/// element-by-element. The type is unsafe because it cannot be deinitialized
/// until the buffer has been finalized by a call to `finish`.
@usableFromInline
@frozen
internal struct _UnsafePartiallyInitializedBuffer<Element> {
    @usableFromInline
    internal var result: _Buffer<Element>
    @usableFromInline
    internal var p: UnsafeMutablePointer<Element>
    @usableFromInline
    internal var remainingCapacity: Int
    
    /// Initialize the buffer with an initial size of `initialCapacity`
    /// elements.
    @inlinable
    @inline(__always) // For performance reasons.
    internal init(initialCapacity: Int) {
        if initialCapacity == 0 {
            result = _Buffer()
        } else {
            result = _Buffer(
                _uninitializedCount: initialCapacity,
                minimumCapacity: 0)
        }
        
        p = result.firstElementAddress
        remainingCapacity = result.capacity
    }
    
    /// Add an element to the buffer, reallocating if necessary.
    @inlinable
    @inline(__always) // For performance reasons.
    internal mutating func add(_ element: Element) {
        if remainingCapacity == 0 {
            // Reallocate.
            let newCapacity = max(_growArrayCapacity(result.capacity), 1)
            var newResult = _Buffer<Element>(
                _uninitializedCount: newCapacity, minimumCapacity: 0)
            p = newResult.firstElementAddress + result.capacity
            remainingCapacity = newResult.capacity - result.capacity
            if !result.isEmpty {
                // This check prevents a data race writting to _swiftEmptyArrayStorage
                // Since count is always 0 there, this code does nothing anyway
                newResult.firstElementAddress.moveInitialize(
                    from: result.firstElementAddress, count: result.capacity)
                result.tailIndex = 0
            }
            (result, newResult) = (newResult, result)
        }
        addWithExistingCapacity(element)
    }
    
    /// Add an element to the buffer, which must have remaining capacity.
    @inlinable
    @inline(__always) // For performance reasons.
    internal mutating func addWithExistingCapacity(_ element: Element) {
        assert(remainingCapacity > 0,
               "_UnsafePartiallyInitializedContiguousArrayBuffer has no more capacity")
        remainingCapacity -= 1
        
        p.initialize(to: element)
        p += 1
    }
    
    /// Finish initializing the buffer, adjusting its count to the final
    /// number of elements.
    ///
    /// Returns the fully-initialized buffer. `self` is reset to contain an
    /// empty buffer and cannot be used afterward.
    @inlinable
    @inline(__always) // For performance reasons.
    internal mutating func finish() -> _Buffer<Element> {
        // Adjust the initialized count of the buffer.
        result.tailIndex = result.capacity - remainingCapacity
        
        return finishWithOriginalCount()
    }
    
    /// Finish initializing the buffer, assuming that the number of elements
    /// exactly matches the `initialCount` for which the initialization was
    /// started.
    ///
    /// Returns the fully-initialized buffer. `self` is reset to contain an
    /// empty buffer and cannot be used afterward.
    @inlinable
    @inline(__always) // For performance reasons.
    internal mutating func finishWithOriginalCount() -> _Buffer<Element> {
        assert(remainingCapacity == result.capacity - result.count,
               "_UnsafePartiallyInitializedContiguousArrayBuffer has incorrect count")
        var finalResult = _Buffer<Element>()
        (finalResult, result) = (result, finalResult)
        remainingCapacity = 0
        return finalResult
    }
}

extension _Buffer: Sequence {
    @inlinable
    __consuming func makeIterator() -> _Buffer<Element>.Iterator {
        return Iterator(base: firstElementAddress, capacity: capacity, count: count, headIndex: headIndex)
    }
    
    @usableFromInline
    struct Iterator: IteratorProtocol {
        
        @usableFromInline
        let wrapPointer: UnsafeMutablePointer<Element>
        
        @usableFromInline
        var countRemaining: Int
        
        @usableFromInline
        var pointer: UnsafeMutablePointer<Element>
        
        @usableFromInline
        let capacity: Int
        
        @inlinable
        mutating func next() -> Element? {
            guard countRemaining > 0 else { return nil }
            if _slowPath(pointer == wrapPointer) { pointer -= capacity }
            
            defer {
                pointer += 1
                countRemaining -= 1
            }
            return pointer.pointee
        }
        
        @inlinable
        init(base: UnsafeMutablePointer<Element>, capacity: Int, count: Int, headIndex: Int) {
            self.wrapPointer = base + capacity
            self.capacity = capacity
            self.pointer = base + headIndex
            self.countRemaining = count
        }
    }
}

extension _Buffer {
    @inlinable
    init(copying other: __owned _Buffer) {
        // TODO: a more efficient implementation by copying memory directly in chunks then discarding the other
        self = _copySequenceToContiguousBuffer(other)
    }
    
    @inlinable
    init(capacity minimumCapacity: Int, copying other: __owned _Buffer) {
        
        let otherCount = other.count
        self = _Buffer<Element>(_uninitializedCount: otherCount, minimumCapacity: minimumCapacity)
        if other.tailIndexIsWrapped {
            let headToEnd = other.capacity - other.headIndex
            firstElementAddress.moveInitialize(from: other.firstElementAddress + other.headIndex, count: headToEnd)
            (firstElementAddress + headToEnd).moveInitialize(from: other.firstElementAddress, count: tailIndex)
            other.headIndex = 0
            other.tailIndex = 0
            other.tailIndexIsWrapped = false
        } else {
            firstElementAddress.moveInitialize(from: other.firstElementAddress + other.headIndex, count: otherCount)
        }
        tailIndex = otherCount
    }
    
    @inline(never)
    @inlinable // @specializable
    internal func _forceCreateUniqueMutableBuffer(
        newCount: Int, requiredCapacity: Int
    ) -> _Buffer<Element> {
        let minimumCapacity = Swift.max(
            requiredCapacity,
            newCount > capacity
                ? _growArrayCapacity(capacity) : capacity
        )

        return _Buffer(
          _uninitializedCount: newCount, minimumCapacity: minimumCapacity)
    }
    
    @inline(never)
    @usableFromInline
    internal mutating func _outlinedMakeUniqueBuffer(bufferCount: Int) {

        if _fastPath(
            requestUniqueMutableBackingBuffer(minimumCapacity: bufferCount) != nil) {
            return
        }
        
        var newBuffer = _forceCreateUniqueMutableBuffer(
            newCount: bufferCount, requiredCapacity: bufferCount)
        _fullBufferOutOfPlaceUpdate(&newBuffer, bufferCount, 0)
    }


    /// Copy the elements in `bounds` from this buffer into uninitialized
    /// memory starting at `target`.  Return a pointer "past the end" of the
    /// just-initialized memory.
    @inlinable
    @discardableResult
    internal __consuming func _copyContents(
        subRange bounds: Range<Int>,
        initializing target: UnsafeMutablePointer<Element>
    ) -> UnsafeMutablePointer<Element> {
        assert(bounds.lowerBound >= 0)
        assert(bounds.upperBound >= bounds.lowerBound)
        assert(bounds.upperBound <= count)

        let initializedCount = bounds.upperBound - bounds.lowerBound
        target.initialize(
            from: firstElementAddress + bounds.lowerBound, count: initializedCount)
        _fixLifetime(owner)
        return target + initializedCount
    }
    
    @inlinable
    internal func _createLogicallyOrderedCopy() -> _Buffer<Element> {
        let newCount = self.count
        var newBuffer = _forceCreateUniqueMutableBuffer(newCount: newCount, requiredCapacity: newCount)
        _logicallyOrderOtherBuffer(&newBuffer)
        return newBuffer
    }
    
    @inlinable
    internal func _logicallyOrderOtherBuffer(_ dest: inout _Buffer<Element>) {
        assert(dest.capacity >= self.count)
        assert(dest.headIndex == 0)
        
        let base = firstElementAddress
        let headPointer = base + headIndex
        
        let destBase = dest.firstElementAddress
        
        if tailIndexIsWrapped {
            let headToEnd = capacity - headIndex
            destBase.initialize(from: headPointer, count: headToEnd)
            (destBase + headToEnd).initialize(from: base, count: tailIndex)
        } else {
            destBase.initialize(from: headPointer, count: self.count)
        }
        dest.tailIndex = self.count
    }
    
    @inlinable
    internal mutating func _reorderingOutOfPlaceReplace<C: Collection>(
        circularRange bounds: Range<Int>,
        with newValues: __owned C,
        count insertCount: Int
    ) where C.Element == Element {
        let growth = insertCount - bounds.count
        let newCount = self.count + growth
        var newBuffer = _forceCreateUniqueMutableBuffer(
          newCount: newCount, requiredCapacity: newCount)
        
        _reorderingOutOfPlaceUpdate(
            dest: &newBuffer,
            headCount: bounds.lowerBound,
            newCount: insertCount,
            initializeNewElements: { (rawMemory, count) in
                var p = rawMemory
                var q = newValues.startIndex
                for _ in 0..<count {
                  p.initialize(to: newValues[q])
                  newValues.formIndex(after: &q)
                  p += 1
                }
                assert(newValues.endIndex == q)
            }
        )
    }
    
    @inline(never)
    @inlinable
    internal mutating func _reorderingOutOfPlaceUpdate(
        dest: inout _Buffer<Element>,
        headCount: Int,
        newCount: Int,
        initializeNewElements:
            ((UnsafeMutablePointer<Element>, _ count: Int) -> ()) = { ptr, count in
                assert(count == 0)
        }
    ) {
        assert(headCount >= 0)
        assert(newCount >= 0)
        
        let sourceCount = self.count
        let tailCount = dest.count - headCount - newCount
        assert(headCount + tailCount <= sourceCount)
        
        let oldCount = sourceCount - headCount - tailCount
        
        let destStart = dest.firstElementAddress
        let newStart = destStart + headCount
        let newEnd = newStart + newCount

        let sourceBase = firstElementAddress
        let sourceStart = sourceBase + headIndex
        
        if let backing = requestUniqueMutableBackingBuffer(minimumCapacity: sourceCount) {
            // we can move instead of copy
            
            
            if tailIndexIsWrapped {
                let theCapacity = capacity
                let capacityPointer = sourceBase + theCapacity
                
                let oldStart = _wrappingMoveInitialize(dest: destStart, source: sourceStart, count: headCount, base: sourceBase, limit: capacityPointer)
                
                let oldEnd = _wrappingDeinitialize(target: oldStart, count: oldCount, base: sourceBase, limit: capacityPointer)
                
                initializeNewElements(newStart, newCount)
                
                _wrappingMoveInitialize(dest: newEnd, source: oldEnd, count: tailCount, base: sourceBase, limit: capacityPointer)
            } else {

                let oldStart = sourceStart + headCount
                
                // Move head items
                destStart.moveInitialize(from: sourceStart, count: headCount)

                // Destroy unused source items
                oldStart.deinitialize(count: oldCount)
                
                initializeNewElements(newStart, newCount)
                
                // Move the tail items
                newEnd.moveInitialize(from: oldStart + oldCount, count: tailCount)
            }

            backing.tailIndex = backing.headIndex
            backing.tailIndexIsWrapped = false
        } else {
            // buffer is not uniquely referenced, so we have to copy not move
            if tailIndexIsWrapped {
                let theCapacity = capacity
                let capacityPointer = sourceBase + theCapacity
                
                let oldStart = _wrappingInitialize(dest: destStart, source: sourceStart, count: headCount, base: sourceBase, limit: capacityPointer)
                
                let possibleEnd = oldStart + oldCount
                
                let oldEnd = possibleEnd > capacityPointer ? possibleEnd - capacity : possibleEnd
                
                initializeNewElements(newStart, newCount)
                
                _wrappingInitialize(dest: newEnd, source: oldEnd, count: tailCount, base: sourceBase, limit: capacityPointer)
            } else {

                let oldStart = sourceStart + headCount
                
                // Move head items
                destStart.initialize(from: sourceStart, count: headCount)
                
                initializeNewElements(newStart, newCount)
                
                // Move the tail items
                newEnd.initialize(from: oldStart + oldCount, count: tailCount)
            }
            _fixLifetime(owner)
        }
        self = dest
    }
    
    /// Initialize the elements of dest by copying the first headCount
    /// items from source, calling initializeNewElements on the next
    /// uninitialized element, and finally by copying the last N items
    /// from source into the N remaining uninitialized elements of dest.
    ///
    /// As an optimization, may move elements out of source rather than
    /// copying when it isUniquelyReferenced.
    @inline(never)
    @inlinable // @specializable
    internal mutating func _fullBufferOutOfPlaceUpdate(
        _ dest: inout _Buffer<Element>,
        _ headCount: Int, // Count of initial source elements to copy/move
        _ newCount: Int,  // Number of new elements to insert
        _ initializeNewElements:
            ((UnsafeMutablePointer<Element>, _ count: Int) -> ()) = { ptr, count in
                assert(count == 0)
        }
    ) {

        assert(headCount >= 0)
        assert(newCount >= 0)
        
        // Count of trailing source elements to copy/move
        let sourceCount = self.count
        let tailCount = dest.count - headCount - newCount
        assert(headCount + tailCount <= sourceCount)
        
        let oldCount = sourceCount - headCount - tailCount
        let destStart = dest.firstElementAddress
        let newStart = destStart + headCount
        let newEnd = newStart + newCount
        
        // Check to see if we have storage we can move from
        if let backing = requestUniqueMutableBackingBuffer(
            minimumCapacity: sourceCount) {
            
            let sourceStart = firstElementAddress
            let oldStart = sourceStart + headCount
            
            // Move the head items
            destStart.moveInitialize(from: sourceStart, count: headCount)
            
            // Destroy unused source items
            oldStart.deinitialize(count: oldCount)
            
            initializeNewElements(newStart, newCount)
            
            // Move the tail items
            newEnd.moveInitialize(from: oldStart + oldCount, count: tailCount)
            
            backing.headIndex = 0
            backing.tailIndex = 0
            backing.tailIndexIsWrapped = false
        }
        else {
            let headStart = 0
            let headEnd = headStart + headCount
            let newStart = _copyContents(
                subRange: headStart..<headEnd,
                initializing: destStart)
            initializeNewElements(newStart, newCount)
            let tailStart = headEnd + oldCount
            let tailEnd = count
            _copyContents(subRange: tailStart..<tailEnd, initializing: newEnd)
        }
        self = dest
    }
}

/// Wrapping `initialize` of a pointer from `source`.
///
/// If the end index `dest` + `count` is beyond `limit`, start again at `base`.
/// - Parameter dest: the pointer to initialize
/// - Parameter source: the pointer to copy from
/// - Parameter count: the number of elements to copy
/// - Parameter base: the base to wrap to
/// - Parameter limit: the limit beyond which to wrap back to base
///
/// - Returns: the pointer after the last address moved from (in `source` or `base`)
@inlinable
@discardableResult
internal func _wrappingInitialize<T>(dest: UnsafeMutablePointer<T>, source: UnsafeMutablePointer<T>, count: Int, base: UnsafeMutablePointer<T>, limit: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    let end = source + count
    if end > limit {
        let partCount = limit - source
        dest.initialize(from: source, count: partCount)
        let remainder = count - partCount
        (dest + partCount).initialize(from: base, count: remainder)
        return base + remainder
    } else {
        dest.initialize(from: source, count: count)
        return end
    }
}

/// Wrapping `moveInitialize` of a pointer from `source`.
///
/// If the end index `dest` + `count` is beyond `limit`, start again at `base`.
/// - Parameter dest: the pointer to initialize
/// - Parameter source: the pointer to move from
/// - Parameter count: the number of elements to move
/// - Parameter base: the base to wrap to
/// - Parameter limit: the limit beyond which to wrap back to base
///
/// - Returns: the pointer after the last address moved from (in `source` or `base`)
@inlinable
@discardableResult
internal func _wrappingMoveInitialize<T>(dest: UnsafeMutablePointer<T>, source: UnsafeMutablePointer<T>, count: Int, base: UnsafeMutablePointer<T>, limit: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    let end = source + count
    if end > limit {
        let partCount = limit - source
        dest.moveInitialize(from: source, count: partCount)
        let remainder = count - partCount
        (dest + partCount).moveInitialize(from: base, count: remainder)
        return base + remainder
    } else {
        dest.moveInitialize(from: source, count: count)
        return end
    }
}

/// Wrapping `deinitialize()` of a pointer.
///
/// If the end index `target` + `count` is beyond `limit`, start again at `base`.
/// - Parameter target: the pointer to deinitialize
/// - Parameter count: the number of elements of pointer to deinitialize
/// - Parameter base: the base to wrap to
/// - Parameter limit: the limit beyond which to wrap back to base
///
/// - Returns: the pointer after the last deinitialized element (in `target` or `base`)
@inlinable
@discardableResult
internal func _wrappingDeinitialize<T>(target: UnsafeMutablePointer<T>, count: Int, base: UnsafeMutablePointer<T>, limit: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    let end = target + count
    if end > limit {
        let partCount = limit - target
        target.deinitialize(count: partCount)
        let remainder = count - partCount
        base.deinitialize(count: remainder)
        return base + remainder
    } else {
        target.deinitialize(count: count)
        return end
    }
}
