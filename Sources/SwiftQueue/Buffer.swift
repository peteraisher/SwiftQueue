/// A base class to represent the storage for a buffer.
@usableFromInline
internal class _StorageBase {
    
    /// The index and capacity information for the storage.
    @usableFromInline
    final var capacityIndicesAndFlag = _CircularBufferBody()
    
    /// The raw pointer to the elements of the storage.
    @usableFromInline
    var _rawPointer: UnsafeMutableRawPointer
    
    /// Initialize a new storage instance.
    @inlinable
    init() {
        _rawPointer = UnsafeMutableRawPointer(&capacityIndicesAndFlag)
    }
}

/// Grow the capacity of a buffer
/// - Parameter capacity: The current capacity.
/// - Returns: The new capacity.
@inlinable
internal func _growBufferCapacity(_ capacity: Int) -> Int {
    return capacity * 2
}

/// A class to represent the storage of an empty buffer.
@usableFromInline
internal class _EmptyStorage: _StorageBase {
}

/// A struct to hold index and capacity information about a circular buffer
@usableFromInline
struct _CircularBufferBody {
    /// The capacity of the buffer.
    @usableFromInline
    var capacity: Int
    
    /// The index of the first element of the circular buffer.
    @usableFromInline
    var headIndex: Int
    
    /// Combines the `tailIndex` with the `tailIndexIsWrapped` flag.
    @usableFromInline
    var tailIndexAndFlag: UInt
    
    /// A flag indicating if the `tailIndex` has wrapped beyond the capacity of the circular buffer.
    @inlinable
    var tailIndexIsWrapped: Bool {
        get {
            return (tailIndexAndFlag & 1) != 0
        }
        set {
            tailIndexAndFlag = newValue ? tailIndexAndFlag | 1 : tailIndexAndFlag & ~1
        }
    }
    
    /// The index beyond the last element of the circular buffer.
    ///
    /// - Note: if `tailIndex` is set to capacity, it wraps back to zero and sets the `tailIndexIsWrapped` flag to `true`
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
    
    /// Initialize with given count and capacity.
    /// - Parameter count: The number of elements currently in the buffer.
    /// - Parameter capacity: The number of elements the buffer can hold.
    @usableFromInline
    init(count: Int, capacity: Int) {
        self.headIndex = 0
        self.tailIndexAndFlag = (count == capacity) ? 1 : UInt(truncatingIfNeeded: count &<< 1)
        self.capacity = capacity
    }
    /// Initialize with zero count and capacity.
    init() {
        self.headIndex = 0
        self.tailIndexAndFlag = 0
        self.capacity = 0
    }
}


/// A single instance of empty storage shared between all empy buffers.
internal var _emptyBufferStorage: _EmptyStorage = _EmptyStorage()

/// The class which stores the elements of a buffer.
@usableFromInline
class _Storage<Element>: _StorageBase {
    
    /// Create a new instance with the given capacity and count.
    ///
    /// - Parameter capacity: The capacity of the created storage.
    /// - Parameter count: The number of elements contained by the storage.
    ///
    /// - Note: If `count` is greater than zero, the elements up to `count` must be manually
    ///     initialized before the storage instance is valid.
    @inlinable
    init(capacity: Int, count: Int) {
        super.init()
        self.capacityIndicesAndFlag = _CircularBufferBody(count: count, capacity: capacity)
        let _elementPointer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        self._rawPointer = UnsafeMutableRawPointer(_elementPointer)
    }
    
    /// The pointer to the first element of the storage.
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

/// A circular buffer of elements used as the backing for a queue.
@usableFromInline
struct _Buffer<Element> {
    
    /// The buffer's storage.
    @usableFromInline
    internal var _storage: _StorageBase
    
    /// The index beyond the last element of the circular buffer.
    ///
    /// Setting `tailIndex` to `capacity` causes the index to wrap round to
    /// zero and sets the flag `tailIndexIsWrapped` to `true`.
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
    
    /// The index of the first element of the circular buffer.
    ///
    /// Setting `headIndex` to `capacity` causes the index to wrap around to
    /// zero and sets the flag `tailIndexIsWrapped` to `false`.
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
    
    /// A flag indicating if the `tailIndex` has wrapped beyond the capacity of the circular buffer.
    ///
    /// If the value is `true`, the elements of the buffer are stored in two regions,
    /// with indices in the ranges ` headIndex ..< capacity` and `0 ..< tailIndex`.
    ///
    /// Otherwise, the elements of the buffer are stored in one region with indices
    /// in the range `headIndex ..< tailIndex`.
    @inlinable
    internal var tailIndexIsWrapped: Bool {
        get {
            return _storage.capacityIndicesAndFlag.tailIndexIsWrapped
        }
        nonmutating set {
            _storage.capacityIndicesAndFlag.tailIndexIsWrapped = newValue
        }
    }
    
    /// The number of elements stored in the buffer.
    @usableFromInline
    internal var count: Int {
        return tailIndex - headIndex + (tailIndexIsWrapped ? capacity : 0)
    }
    
    /// A boolean value indicating whether the buffer is empty.
    @usableFromInline
    internal var isEmpty: Bool {
        count == 0
    }
    
    /// The capacity of the buffer's storage, i.e. the maximum number of elements the buffer
    /// can hold without requiring new storage.
    @usableFromInline
    internal var capacity: Int { return _storage.capacityIndicesAndFlag.capacity }
    
    /// A pointer to the first element of the buffer's storage.
    /// - Note: This is **not** generally the same as the logical first element of the buffer.
    @usableFromInline
    internal var firstElementAddress: UnsafeMutablePointer<Element> {
        return _storage._rawPointer.assumingMemoryBound(to: Element.self)
    }
    
    /// Create a linear index to the underlying storage from a circular index in the range `0 ..< count`
    /// without checking its validity.
    /// - Parameter circularIndex: The circular index in the range `0 ..< count`.
    /// - Returns: The corresponding linear index in the underlying storage.
    @inlinable
    func _uncheckedLinearIndex(from circularIndex: Int) -> Int {
        return (headIndex + circularIndex) % capacity
    }
    
    /// Get the element at the given circular index without
    /// checking the validity of the index.
    /// - Parameter index: The circular index in the range `0 ..< count`.
    /// - Returns: The corresponding element.
    @inlinable
    func getElementAtUncheckedCircularIndex(_ index: Int) -> Element {
        let linearIndex = _uncheckedLinearIndex(from: index)
        return self[linearIndex]
    }
    
    /// Get a pointer to the element at the given circular index wihout checking the validity of the index.
    /// - Parameter index: The circular index in the range `0 ..< count`.
    /// - Returns: A pointer to the corresponding element.
    @inlinable
    func getElementPointerAtUncheckedCircularIndex(_ index: Int) -> UnsafeMutablePointer<Element> {
        let linearIndex = _uncheckedLinearIndex(from: index)
        return firstElementAddress + linearIndex
    }
    
    /// Get the element at the given linear index.
    /// - Parameter i: The linear index of the element to return.
    /// - Returns: The element at the linear index specified.
    @inlinable
    @inline(__always)
    func getElement(i: Int) -> Element {
        return firstElementAddress[i]
    }
    
    /// Access the element at the given linear index.
    /// - Parameter i: The linear index of the element to access.
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
    
    /// Is the buffer uniquely referenced.
    /// - Returns: `true` if the buffer's storage is uniquely referenced; otherwise `false`.
    @inlinable
    internal mutating func isUniquelyReferenced() -> Bool {
        return isKnownUniquelyReferenced(&_storage)
    }
    
    /// The object that keeps reference types alive.
    @inlinable
    internal var owner: AnyObject {
      return _storage
    }
    
    /// Create a buffer with empty storage.
    @inlinable
    internal init() {
        _storage = _EmptyStorage()
    }
    
    /// Request a unique mutable buffer with the given capacity.
    /// - Parameter minimumCapacity: The minimum capacity for the buffer.
    /// - Returns: This buffer if it has sufficient capacity; othewise `nil`.
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
    /// result's `.firstElementAddress` or set the result's `.tailIndex`
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


/// Copy a sequence into a new buffer.
/// - Parameter source: The sequence to copy.
/// - Returns: A buffer containing the elements of `source`.
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
            let newCapacity = max(_growBufferCapacity(result.capacity), 1)
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
    
    /// A non-destructive iterator over this buffer.
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
        
        
        /// Create an iterator for a buffer.
        /// - Parameter base: The buffer's `firstElementAddress`.
        /// - Parameter capacity: The buffer's `capacity`.
        /// - Parameter count: The buffer's `count`.
        /// - Parameter headIndex: The buffer's `headIndex`.
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
    
    /// Force the creation of a new unique buffer with a given count and minimum capacity.
    ///
    /// If `newCount` is greater than `requiredCapacity`, the capacity of the new buffer
    /// is grown using `_growBufferCapacity`.
    /// - Parameter newCount: The count of the new buffer.
    /// - Parameter requiredCapacity: The required capacity.
    /// - Returns: An uninitialized unique buffer with `newCount` elements and sufficient capacity.
    @inline(never)
    @inlinable
    internal func _forceCreateUniqueMutableBuffer(
        newCount: Int, requiredCapacity: Int
    ) -> _Buffer<Element> {
        let minimumCapacity = Swift.max(
            requiredCapacity,
            newCount > capacity
                ? _growBufferCapacity(capacity) : capacity
        )

        return _Buffer(
          _uninitializedCount: newCount, minimumCapacity: minimumCapacity)
    }
    
    /// Make the buffer unique by copying to a new buffer if necessary.
    /// - Parameter bufferCount: The number of elements in the buffer.
    @inline(never)
    @usableFromInline
    internal mutating func _outlinedMakeUniqueBuffer(bufferCount: Int) {

        if _fastPath(
            requestUniqueMutableBackingBuffer(minimumCapacity: bufferCount) != nil) {
            return
        }
        
        var newBuffer = _forceCreateUniqueMutableBuffer(
            newCount: bufferCount, requiredCapacity: bufferCount)
        _reorderingOutOfPlaceUpdate(dest: &newBuffer, headCount: bufferCount, newCount: 0)
    }
    
    /// Replace elements of the buffer and reorder the remaining elements into logical order.
    /// - Parameter bounds: The range of elements to replace, using circular indices.
    /// - Parameter newValues: The values to replace by.
    /// - Parameter insertCount: The number of values to be inserted.
    /// - Note: The number of elements in `newValues` must be equal to `insertCount`.
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
    
    /// Out of place update with reordering.
    ///
    /// Initialize the elements of `dest` by copying the first `headCount`
    /// items from `source`, calling `initializeNewElements` on the next
    /// uninitialized element, and finally by copying the last N items
    /// from `source` into the N remaining uninitialized elements of `dest`.
    ///
    /// This function also logically orders the elements in `dest` during the copy
    /// and then sets `self` to `dest`.
    ///
    /// As an optimization, may move elements out of `source` rather than
    /// copying when it `isUniquelyReferenced`.
    ///
    /// - Parameter dest: The buffer in which to perform the update.
    /// - Parameter headCount: The number of elements to initially copy.
    /// - Parameter newCount: The number of new elements to be initialized.
    /// - Parameter initializeNewElements: A closure to initialize the new elements.
    ///
    /// - Note: If the optional parameter `initializeNewElements` is not provided,
    ///     `newCount` must be zero.
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
