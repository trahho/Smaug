//
//  CyclicEncoder.swift
//  CyclicCoding
//
//  Created by Greg Omelaenko on 20/8/18.
//  Copyright © 2018 Greg Omelaenko. All rights reserved.
//

import Foundation

/// Encodes a given `Encodable` object graph, detecting duplicates and cycle, into a flattened representation suitable for serialisation.
///
/// - Deduplication: any object (`AnyObject`) which is present in object graph given multiple times will only be encoded once, and will be appropriately referenced everywhere else it appears.
///     - Object identity is determined by `ObjectIdentifier`. Any custom equality operators that are or are not implemented will not affect encoding.
///
/// - Cycles in the object graph **cannot** be encoded as-is: use `WeakCycleBreaker` or `UnownedCycleBreaker` to break them.
///     - If you attempt to encode an object graph containing a cycle without a cycle breaker, an error will be thrown.
public class CyclicEncoder {
    public init() {}

    public func flatten<T: Encodable>(_ value: T) throws -> FlattenedContainer {
        let encoder = _Encoder(userInfo: userInfo)
        return try encoder.encodeRoot(value)
    }

    /// A user-provided dictionary which objects can access (read-only) via `encoder.userInfo` during encoding with `encode(to:)`.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
}

private final class _Encoder: Encoder {
    var codingPath: [CodingKey]
    private var containers: [EncodingContainer]

    enum ObjectUsage {
        case once(Resolvable<Value>)
        case multiple(ReferenceIndex)
    }

    private var objectUsage: [ObjectIdentifier: ObjectUsage]
    private var referenced: [Resolvable<Value>]
    /// The set of objects currently being encoded. Used for identifying cycles.
    private var encodingStack: Set<ObjectIdentifier>
    /// For each object protected by a cycle breaker, the number of cycle breakers encountered.
    private var cycleBreakers: [ObjectIdentifier: Int]

    private(set) var userInfo: [CodingUserInfoKey: Any]

    init(userInfo: [CodingUserInfoKey: Any]) {
        codingPath = []
        containers = []

        self.userInfo = userInfo

        objectUsage = [:]
        referenced = []
        encodingStack = []
        cycleBreakers = [:]

        // overwrites that key in the dictionary, but people shouldn't really use a key with that name anyway
        self.userInfo[cycleBreakerEncoderUserInfoKey] = self
    }

    func encodeRoot<T: Encodable>(_ value: T) throws -> FlattenedContainer {
        defer {
            objectUsage = [:]
            referenced = []
        }
        let root = try box(value)
        return FlattenedContainer(referenced: referenced.map { $0.resolve() }, root: root.resolve())
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    var canEncodeNewValue: Bool {
        codingPath.count == containers.count
    }

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container: EncodingContainer.Keyed
        if canEncodeNewValue {
            container = .init([:])
            containers.append(.keyed(container))
        } else {
            guard case let .keyed(topContainer)? = containers.last else {
                preconditionFailure("USER ERROR: Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            container = topContainer
        }
        return KeyedEncodingContainer(KeyedContainerWrapper<Key>(encoder: self, codingPath: codingPath, wrapping: container))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container: EncodingContainer.Unkeyed
        if canEncodeNewValue {
            container = .init([])
            containers.append(.unkeyed(container))
        } else {
            guard case let .unkeyed(topContainer)? = containers.last else {
                preconditionFailure("USER ERROR: Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            container = topContainer
        }
        return UnkeyedContainerWrapper(encoder: self, codingPath: codingPath, wrapping: container)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }
}

extension _Encoder {
    func boxNil() -> Resolvable<ValueOrReference> { .resolved(.value(.nil)) }
    func box(_ value: Bool) -> Resolvable<ValueOrReference> { .resolved(.value(.boolean(value))) }
    func box(_ value: String) -> Resolvable<ValueOrReference> { .resolved(.value(.string(value))) }
    func box(_ value: Double) -> Resolvable<ValueOrReference> { .resolved(.value(.double(value))) }
    func box(_ value: Float) -> Resolvable<ValueOrReference> { .resolved(.value(.float(value))) }
    func box(_ value: Int) -> Resolvable<ValueOrReference> { .resolved(.value(.int(value))) }
    func box(_ value: Int8) -> Resolvable<ValueOrReference> { .resolved(.value(.int8(value))) }
    func box(_ value: Int16) -> Resolvable<ValueOrReference> { .resolved(.value(.int16(value))) }
    func box(_ value: Int32) -> Resolvable<ValueOrReference> { .resolved(.value(.int32(value))) }
    func box(_ value: Int64) -> Resolvable<ValueOrReference> { .resolved(.value(.int64(value))) }
    func box(_ value: UInt) -> Resolvable<ValueOrReference> { .resolved(.value(.uint(value))) }
    func box(_ value: UInt8) -> Resolvable<ValueOrReference> { .resolved(.value(.uint8(value))) }
    func box(_ value: UInt16) -> Resolvable<ValueOrReference> { .resolved(.value(.uint16(value))) }
    func box(_ value: UInt32) -> Resolvable<ValueOrReference> { .resolved(.value(.uint32(value))) }
    func box(_ value: UInt64) -> Resolvable<ValueOrReference> { .resolved(.value(.uint64(value))) }

    private func actuallyBox<T: Encodable>(_ value: T) throws -> Resolvable<Value> {
        let depth = containers.count
        do {
            try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if containers.count > depth {
                containers.removeLast()
            }
            throw error
        }

        precondition(containers.count == depth + 1, "BUG: Encoding a value should push exactly one additional storage.")

        return containers.removeLast().finalise()
    }

    func box<T: Encodable>(_ value: T) throws -> Resolvable<ValueOrReference> {
        if T.self is AnyClass {
            // deduplicate objects
            let id = ObjectIdentifier(value as AnyObject)
            // we only allow cycles if there is an active cycle breaker to ensure it's actually possible to decode this later
            guard encodingStack.insert(id).inserted || cycleBreakers[id, default: 0] > 0 else {
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "A cycle was encountered while encoding an object. Break this cycle using a Weak/UnownedCycleBreaker<\(T.self)>."))
            }
            // this object has already been encoded, so we don't need to encode it again
            if let usage = objectUsage[id] {
                let refIndex: ReferenceIndex
                switch usage {
                // this object has only been used once before, so we need to give it a reference number
                case let .once(value):
                    referenced.append(value)
                    refIndex = ReferenceIndex(referenced.endIndex - 1)
                    objectUsage[id] = .multiple(refIndex)
                // this object has already been used multiple times and given a reference number
                case let .multiple(index):
                    refIndex = index
                }
                return .resolved(.reference(refIndex))
            } else {
                // this object has not been encoded before
                var boxed: Resolvable<Value> = .deferred {
                    preconditionFailure("BUG: tried to resolve the object before it was encoded.")
                }
                objectUsage[id] = .once(.deferred {
                    boxed.resolve()
                })
                boxed = try actuallyBox(value)

                guard encodingStack.remove(id) != nil else {
                    preconditionFailure("BUG: an object was somehow removed from the encoding stack.")
                }
                return .deferred {
                    // this is a strong reference cycle, but will be broken when this closure is thrown away after encoding
                    guard let usage = self.objectUsage[id] else {
                        preconditionFailure("BUG: Previously used object has disappeared from objectUsage table.")
                    }
                    switch usage {
                    case let .once(value):
                        return .value(value.resolve())
                    case let .multiple(index):
                        return .reference(index)
                    }
                }
            }
        } else {
            // T is not a reference type
            return try actuallyBox(value).map { .value($0) }
        }
    }
}

extension _Encoder: CycleBreakerEncoder {
    func encodeBreakingCycle<T: Encodable & AnyObject>(_ value: T) throws {
        let id = ObjectIdentifier(value)
        cycleBreakers[id, default: 0] += 1
        try encode(value)
        cycleBreakers[id]! -= 1
    }
}

private enum Resolvable<T> {
    case resolved(T)
    case deferred(() -> T)

    func resolve() -> T {
        switch self {
        case let .resolved(v):
            return v
        case let .deferred(f):
            return f()
        }
    }

    func map<U>(_ transform: @escaping (T) -> U) -> Resolvable<U> {
        switch self {
        case let .resolved(val):
            return .resolved(transform(val))
        case let .deferred(f):
            return .deferred {
                transform(f())
            }
        }
    }
}

private enum EncodingContainer {
    typealias Keyed = MutableBox<[String: Resolvable<ValueOrReference>]>
    typealias Unkeyed = MutableBox<[Resolvable<ValueOrReference>]>
    typealias Single = MutableBox<Resolvable<ValueOrReference>>

    case keyed(Keyed)
    case unkeyed(Unkeyed)
    case single(Single)

    func finalise() -> Resolvable<Value> {
        switch self {
        case let .keyed(contents):
            return .deferred { .keyed(contents[].mapValues { $0.resolve() }) }
        case let .unkeyed(contents):
            return .deferred { .unkeyed(contents[].map { $0.resolve() }) }
        case let .single(contents):
            return .deferred { .single(contents[].resolve()) }
        }
    }
}

enum SuperKey: String, CodingKey {
    case `super`
}

private struct KeyedContainerWrapper<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
    let encoder: _Encoder
    private(set) var codingPath: [CodingKey]
    let container: EncodingContainer.Keyed

    init(encoder: _Encoder, codingPath: [CodingKey], wrapping container: EncodingContainer.Keyed) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    mutating func encodeNil(forKey key: Key) { container[][key.stringValue] = encoder.boxNil() }
    mutating func encode(_ value: Bool, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: String, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Double, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Float, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Int, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Int8, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Int16, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Int32, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: Int64, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: UInt, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: UInt8, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: UInt16, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: UInt32, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }
    mutating func encode(_ value: UInt64, forKey key: Key) { container[][key.stringValue] = encoder.box(value) }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        encoder.codingPath.append(key)
        defer { encoder.codingPath.removeLast() }
        guard container[][key.stringValue] == nil else {
            preconditionFailure("USER ERROR: Tried to encode duplicate entry for key \(key.stringValue): \(value).")
        }
        container[][key.stringValue] = try encoder.box(value)
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let nested = EncodingContainer.Keyed([:])
        guard container[][key.stringValue] == nil else {
            preconditionFailure("USER ERROR: Tried to encode duplicate entry for key \(key.stringValue).")
        }
        container[][key.stringValue] = .deferred {
            .value(.keyed(nested[].mapValues { $0.resolve() }))
        }

        codingPath.append(key)
        defer { codingPath.removeLast() }

        return KeyedEncodingContainer(KeyedContainerWrapper<NestedKey>(encoder: encoder, codingPath: codingPath, wrapping: nested))
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let nested = EncodingContainer.Unkeyed([])
        guard container[][key.stringValue] == nil else {
            preconditionFailure("USER ERROR: Tried to encode duplicate entry for key \(key.stringValue).")
        }
        container[][key.stringValue] = .deferred {
            .value(.unkeyed(nested[].map { $0.resolve() }))
        }

        codingPath.append(key)
        defer { codingPath.removeLast() }

        return UnkeyedContainerWrapper(encoder: encoder, codingPath: codingPath, wrapping: nested)
    }

    private mutating func superEncoder(forAnyKey key: CodingKey) -> Encoder {
        codingPath.append(key)
        defer { codingPath.removeLast() }

        guard container[][key.stringValue] == nil else {
            preconditionFailure("USER ERROR: Tried to encode duplicate entry for key \(key.stringValue).")
        }

        let superEncoder = SuperEncoder(encoder: encoder, codingPath: codingPath, wrapping: nil)
        container[][key.stringValue] = .deferred {
            guard let container = superEncoder.container else {
                preconditionFailure("USER ERROR: A super encoder was requested but nothing was encoded to it.")
            }
            return .value(container.finalise().resolve())
        }

        return superEncoder
    }

    mutating func superEncoder() -> Encoder {
        superEncoder(forAnyKey: SuperKey.super)
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        superEncoder(forAnyKey: key)
    }
}

struct IndexKey: CodingKey {
    var index: Int

    init(index: Int) {
        self.index = index
    }

    var intValue: Int? {
        index
    }

    init?(intValue: Int) {
        self.init(index: intValue)
    }

    var stringValue: String {
        "\(index)"
    }

    init?(stringValue: String) {
        guard let intValue = Int(stringValue) else {
            return nil
        }
        self.init(intValue: intValue)
    }
}

private struct UnkeyedContainerWrapper: UnkeyedEncodingContainer {
    let encoder: _Encoder
    private(set) var codingPath: [CodingKey]
    let container: EncodingContainer.Unkeyed

    var count: Int {
        container[].count
    }

    init(encoder: _Encoder, codingPath: [CodingKey], wrapping container: EncodingContainer.Unkeyed) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    mutating func encodeNil() { container[].append(encoder.boxNil()) }
    mutating func encode(_ value: Bool) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: String) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Double) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Float) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Int) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Int8) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Int16) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Int32) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: Int64) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: UInt) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: UInt8) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: UInt16) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: UInt32) { container[].append(encoder.box(value)) }
    mutating func encode(_ value: UInt64) { container[].append(encoder.box(value)) }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        encoder.codingPath.append(IndexKey(index: count))
        defer { encoder.codingPath.removeLast() }
        container[].append(try encoder.box(value))
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        codingPath.append(IndexKey(index: count))
        defer { codingPath.removeLast() }

        let nested = EncodingContainer.Keyed([:])
        container[].append(.deferred {
            .value(.keyed(nested[].mapValues { $0.resolve() }))
        })

        return KeyedEncodingContainer(KeyedContainerWrapper<NestedKey>(encoder: encoder, codingPath: codingPath, wrapping: nested))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        codingPath.append(IndexKey(index: count))
        defer { codingPath.removeLast() }

        let nested = EncodingContainer.Unkeyed([])
        container[].append(.deferred {
            .value(.unkeyed(nested[].map { $0.resolve() }))
        })

        return UnkeyedContainerWrapper(encoder: encoder, codingPath: codingPath, wrapping: nested)
    }

    mutating func superEncoder() -> Encoder {
        codingPath.append(IndexKey(index: count))
        defer { codingPath.removeLast() }

        let superEncoder = SuperEncoder(encoder: encoder, codingPath: codingPath, wrapping: nil)
        container[].append(.deferred {
            guard let container = superEncoder.container else {
                preconditionFailure("USER ERROR: A super encoder was requested but nothing was encoded to it.")
            }
            return .value(container.finalise().resolve())
        })

        return superEncoder
    }
}

extension _Encoder: SingleValueEncodingContainer {
    private func assertCanEncodeNewValue() {
        precondition(canEncodeNewValue, "USER ERROR: Attempt to encode value through single value container when value has already been encoded.")
    }

    func encodeNil() { assertCanEncodeNewValue(); containers.append(.single(.init(boxNil()))) }
    func encode(_ value: Bool) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: String) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Double) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Float) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Int) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Int8) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Int16) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Int32) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: Int64) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: UInt) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: UInt8) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: UInt16) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: UInt32) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }
    func encode(_ value: UInt64) { assertCanEncodeNewValue(); containers.append(.single(.init(box(value)))) }

    func encode<T>(_ value: T) throws where T: Encodable {
        assertCanEncodeNewValue()
        containers.append(.single(.init(try box(value))))
    }
}

private final class SuperEncoder: Encoder {
    let encoder: _Encoder
    private(set) var codingPath: [CodingKey]
    private(set) var container: EncodingContainer?

    init(encoder: _Encoder, codingPath: [CodingKey], wrapping container: EncodingContainer?) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    var userInfo: [CodingUserInfoKey: Any] {
        // SuperEncoder does _not_ conform to CycleBreakerEncoder, and there is no need for it to
        var userInfo = encoder.userInfo
        userInfo[cycleBreakerEncoderUserInfoKey] = nil
        return userInfo
    }

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let keyed: EncodingContainer.Keyed
        if let container = container {
            guard case let .keyed(k) = container else {
                preconditionFailure("USER ERROR: Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            keyed = k
        } else {
            keyed = .init([:])
            container = .keyed(keyed)
        }
        return KeyedEncodingContainer(KeyedContainerWrapper<Key>(encoder: encoder, codingPath: codingPath, wrapping: keyed))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let unkeyed: EncodingContainer.Unkeyed
        if let container = container {
            guard case let .unkeyed(u) = container else {
                preconditionFailure("USER ERROR: Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            unkeyed = u
        } else {
            unkeyed = .init([])
            container = .unkeyed(unkeyed)
        }
        return UnkeyedContainerWrapper(encoder: encoder, codingPath: codingPath, wrapping: unkeyed)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        if let container = container {
            guard case .single = container else {
                preconditionFailure("USER ERROR: Attempt to push new single value encoding container when already previously encoded at this path.")
            }
        } else {
            container = .single(MutableBox(.deferred {
                preconditionFailure("USER ERROR: Nothing was encoded in the single value container.")
            }))
        }
        return self
    }
}

extension SuperEncoder: SingleValueEncodingContainer {
    private func assertCanEncodeSingleValue() {
        guard case let .single(box)? = container, case .deferred = box[] else {
            preconditionFailure("USER ERROR: Attempt to encode value thorugh single value container when value has already been encoded.")
        }
    }

    func encodeNil() throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.boxNil())) }
    func encode(_ value: Bool) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: String) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Double) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Float) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Int) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Int8) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Int16) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Int32) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: Int64) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: UInt) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: UInt8) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: UInt16) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: UInt32) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode(_ value: UInt64) throws { assertCanEncodeSingleValue(); container = .single(.init(encoder.box(value))) }
    func encode<T>(_: T) throws where T: Encodable {}
}
