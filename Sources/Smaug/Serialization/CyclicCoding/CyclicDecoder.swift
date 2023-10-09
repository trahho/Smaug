//
//  CyclicDecoder.swift
//  CyclicCoding
//
//  Created by Greg Omelaenko on 21/8/18.
//  Copyright © 2018 Greg Omelaenko. All rights reserved.
//

import Foundation

/// Decodes an object graph from a flattened representation, correctly reconstructing duplicate objects and cycles which use a cycle breaker.
///
/// - Deduplication: an object which is present once in the flattened representation and referenced multiple times will only be decoded once, and all calls to `decode` for that object will return the same instance.
/// - Cycles in the object graph **cannot** be decoded unless a `WeakCycleBreaker` or `UnownedCycleBreaker` is used to break the cycle.
///     - `CyclicEncoder` will not encode any cycles which cannot successfully be decoded. The only way an undecodable cycle could be present in the flattened representation is if it were manually created.
public class CyclicDecoder {
    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from flattened: FlattenedContainer) throws -> T {
        let decoder = _Decoder(referenced: flattened.referenced, userInfo: userInfo)
        return try decoder.unbox(flattened.root, as: type)
    }

    /// A user-provided dictionary which objects can access (read-only) via `decoder.userInfo` during encoding with `init(from:)`.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
}

private class _Decoder: Decoder {
    var codingPath: [CodingKey]
    private var containers: [DecodingContainer]

    enum ObjectState {
        case undecoded(Value)
        case decoding(completion: [(AnyObject) throws -> Void])
        case decoded(AnyObject)
    }

    private var referenced: [ObjectState]
    /// A function to provide a resolved value to the most recently encountered cycle breaker. Set when one is encountered, and unset when an appropriate object is found to fill it with.
    private var cycleBreakerFiller: ((AnyObject) -> Void)?

    private(set) var userInfo: [CodingUserInfoKey: Any]

    init(referenced: [Value], userInfo: [CodingUserInfoKey: Any]) {
        codingPath = []
        containers = []

        self.userInfo = userInfo

        self.referenced = referenced.map { .undecoded($0) }

        // overwrites that key in the dictionary, but people shouldn't really use a key with that name anyway
        self.userInfo[cycleBreakerDecoderUserInfoKey] = self
    }

    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case let .keyed(container)? = containers.last else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .keyed, reality: containers.last)
        }
        return KeyedDecodingContainer(KeyedContainerWrapper(decoder: self, container: container))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .unkeyed(container)? = containers.last else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .unkeyed, reality: containers.last)
        }
        return UnkeyedContainerWrapper(decoder: self, container: container)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }
}

private extension DecodingError {
    static func _containerMismatch(at path: [CodingKey], expectation: DecodingContainer.Kind, reality: DecodingContainer?) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(String(describing: reality)) instead."
        return .typeMismatch(expectation.type, Context(codingPath: path, debugDescription: description))
    }

    static func _containerMismatch(at path: [CodingKey], expectation: DecodingContainer.Kind, reality: Value) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(String(describing: reality)) instead."
        return .typeMismatch(expectation.type, Context(codingPath: path, debugDescription: description))
    }

    static func _unboxMismatch(at path: [CodingKey], expectation: Any.Type, reality: Value) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(reality) instead."
        return DecodingError.typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }
}

extension _Decoder {
    private func unreferencedValue(_ boxed: ValueOrReference) throws -> Value {
        switch boxed {
        case let .value(value):
            return value
        case .reference:
            throw DecodingError.typeMismatch(Value.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a value, found a reference."))
        }
    }

    func unboxNil(_ boxed: ValueOrReference) -> Bool {
        // this is more of a check than a forced unboxing, so we shouldn't throw if there's a value
        guard case .nil? = try? unreferencedValue(boxed) else {
            return false
        }
        return true
    }

    func unbox(_ boxed: ValueOrReference, as _: Bool.Type) throws -> Bool {
        let value = try unreferencedValue(boxed)
        guard case let .boolean(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Bool.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: String.Type) throws -> String {
        let value = try unreferencedValue(boxed)
        guard case let .string(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: String.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Double.Type) throws -> Double {
        let value = try unreferencedValue(boxed)
        guard case let .double(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Double.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Float.Type) throws -> Float {
        let value = try unreferencedValue(boxed)
        guard case let .float(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Float.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Int.Type) throws -> Int {
        let value = try unreferencedValue(boxed)
        guard case let .int(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Int.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Int8.Type) throws -> Int8 {
        let value = try unreferencedValue(boxed)
        guard case let .int8(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Int.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Int16.Type) throws -> Int16 {
        let value = try unreferencedValue(boxed)
        guard case let .int16(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Int16.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Int32.Type) throws -> Int32 {
        let value = try unreferencedValue(boxed)
        guard case let .int32(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Int32.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: Int64.Type) throws -> Int64 {
        let value = try unreferencedValue(boxed)
        guard case let .int64(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: Int64.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: UInt.Type) throws -> UInt {
        let value = try unreferencedValue(boxed)
        guard case let .uint(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: UInt.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: UInt8.Type) throws -> UInt8 {
        let value = try unreferencedValue(boxed)
        guard case let .uint8(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: UInt8.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: UInt16.Type) throws -> UInt16 {
        let value = try unreferencedValue(boxed)
        guard case let .uint16(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: UInt16.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: UInt32.Type) throws -> UInt32 {
        let value = try unreferencedValue(boxed)
        guard case let .uint32(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: UInt32.self, reality: value) }
        return unboxed
    }

    func unbox(_ boxed: ValueOrReference, as _: UInt64.Type) throws -> UInt64 {
        let value = try unreferencedValue(boxed)
        guard case let .uint64(unboxed) = value else { throw DecodingError._unboxMismatch(at: codingPath, expectation: UInt64.self, reality: value) }
        return unboxed
    }

    private func actuallyUnbox<T: Decodable>(_ value: Value, as type: T.Type) throws -> T {
        containers.append(DecodingContainer(value))
        defer { containers.removeLast() }
        return try type.init(from: self)
    }

    /// Attempts to unbox `boxed`.
    ///
    /// If `boxed`:
    /// - Isn't referenced, has not been seen before, or has already been decoded: `completion` will be called _before_ this method returns.
    /// - Is already being decoded (a cycle is present): adds `completion` to its index in the `referenced` table.
    private func delayableUnbox<T: Decodable>(_ boxed: ValueOrReference, as type: T.Type, completion: @escaping (T) -> Void) throws {
        switch boxed {
        case let .value(value):
            completion(try actuallyUnbox(value, as: type))
        case let .reference(index):
            let convertingCompletion: (AnyObject) throws -> Void = { [unowned self] in
                guard let object = $0 as? T else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected to decode \(type) but found \($0), decoded from: \(boxed)."))
                }
                completion(object)
            }
            switch referenced[index.value] {
            case let .undecoded(value):
                referenced[index.value] = .decoding(completion: [convertingCompletion])
                let object = try actuallyUnbox(value, as: type)
                // If this fails, either the data was corrupted (or manually produced), or perhaps the data model replaced a class with a struct?
                precondition(type is AnyClass, "Type \(type) for a referenced object must be a class.")
                guard case let .decoding(completions) = referenced[index.value] else {
                    preconditionFailure("BUG: object was decoded twice.")
                }
                referenced[index.value] = .decoded(object as AnyObject)
                try completions.forEach { try $0(object as AnyObject) }
            case let .decoding(completions):
                referenced[index.value] = .decoding(completion: completions + [convertingCompletion])
            case let .decoded(object):
                try convertingCompletion(object)
            }
        }
    }

    func unbox<T: Decodable>(_ boxed: ValueOrReference, as type: T.Type) throws -> T {
        var toFill: T?
        try delayableUnbox(boxed, as: type) { unboxed in
            toFill = unboxed
        }
        // the only time completion will be delayed is if there's a cycle without a CycleBreaker in it,
        // since a CycleBreaker will call the internal method decode(_, completion:) instead of this method.
        guard let value = toFill else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Encountered a cycle while trying to decode object of type \(T.self). It should not have been possible to encode this data."))
        }
        return value
    }
}

extension _Decoder: CycleBreakerDecoder {
    func decode<T: Decodable>(_ type: T.Type, completion: @escaping (T) -> Void) throws {
        let boxed = try topContainerSingleValue()
        try delayableUnbox(boxed, as: type, completion: completion)
    }
}

private enum DecodingContainer {
    typealias Keyed = [String: ValueOrReference]
    typealias Unkeyed = [ValueOrReference]
    typealias Single = ValueOrReference

    case keyed(Keyed)
    case unkeyed(Unkeyed)
    case single(Single)

    enum Kind: CustomStringConvertible {
        case keyed
        case unkeyed
        case single

        var type: Any.Type {
            switch self {
            case .keyed: return Keyed.self
            case .unkeyed: return Unkeyed.self
            case .single: return Single.self
            }
        }

        var description: String {
            switch self {
            case .keyed: return "keyed decoding container"
            case .unkeyed: return "unkeyed decoding container"
            case .single: return "single value decoding container"
            }
        }
    }

    init(_ value: Value) {
        switch value {
        case .nil, .boolean, .string, .float, .double, .int, .int8, .int16, .int32, .int64, .uint, .uint8, .uint16, .uint32, .uint64:
            self = .single(.value(value))
        case let .keyed(contents):
            self = .keyed(contents)
        case let .unkeyed(contents):
            self = .unkeyed(contents)
        case let .single(contents):
            self = .single(contents)
        }
    }
}

private struct KeyedContainerWrapper<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
    let decoder: _Decoder
    private(set) var codingPath: [CodingKey]
    let container: DecodingContainer.Keyed

    init(decoder: _Decoder, container: DecodingContainer.Keyed) {
        self.decoder = decoder
        codingPath = decoder.codingPath
        self.container = container
    }

    var allKeys: [Key] {
        container.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        container[key.stringValue] != nil
    }

    func decode<T>(_: T.Type, forKey key: Key, unboxWith unbox: (ValueOrReference) throws -> T) throws -> T {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key.debugDescription)."))
        }

        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        return try unbox(entry)
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try decode(Bool.self, forKey: key, unboxWith: decoder.unboxNil)
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Bool.self) }) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: String.self) }) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Double.self) }) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Float.self) }) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Int.self) }) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Int8.self) }) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Int16.self) }) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Int32.self) }) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: Int64.self) }) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: UInt.self) }) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: UInt8.self) }) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: UInt16.self) }) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: UInt32.self) }) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: UInt64.self) }) }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        try decode(type, forKey: key, unboxWith: { try decoder.unbox($0, as: type) })
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let valOrRef = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(key)."))
        }
        guard case let .value(value) = valOrRef else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Found a reference where a value for a nested keyed container was expected.")
        }
        guard case let .keyed(container) = value else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .keyed, reality: value)
        }
        return KeyedDecodingContainer(KeyedContainerWrapper<NestedKey>(decoder: decoder, container: container))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let valOrRef = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get \(UnkeyedDecodingContainer.self) -- no value found for key \(key)."))
        }
        guard case let .value(value) = valOrRef else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Found a reference where a value for a nested unkeyed container was expected.")
        }
        guard case let .unkeyed(container) = value else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .unkeyed, reality: value)
        }
        return UnkeyedContainerWrapper(decoder: decoder, container: container)
    }

    func superDecoder(forAnyKey key: CodingKey) throws -> Decoder {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let valOrRef = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get super decoder -- no value found for key \(key)."))
        }
        guard case let .value(value) = valOrRef else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "\(self): Found a reference for key \(key) where a value for a super decoder was expected."))
        }
        return SuperDecoder(decoder: decoder, container: DecodingContainer(value))
    }

    func superDecoder() throws -> Decoder {
        try superDecoder(forAnyKey: SuperKey.super)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        try superDecoder(forAnyKey: key)
    }
}

private struct UnkeyedContainerWrapper: UnkeyedDecodingContainer {
    let decoder: _Decoder
    private(set) var codingPath: [CodingKey]
    let container: DecodingContainer.Unkeyed

    private(set) var currentIndex: Int = 0

    init(decoder: _Decoder, container: DecodingContainer.Unkeyed) {
        self.decoder = decoder
        codingPath = decoder.codingPath
        self.container = container
    }

    var count: Int? {
        container.count
    }

    var isAtEnd: Bool {
        currentIndex >= count!
    }

    private mutating func decode<T>(_ type: T.Type, unboxWith unbox: (ValueOrReference) throws -> T) throws -> T {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(IndexKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }

        let decoded = try unbox(container[currentIndex])

        currentIndex += 1
        return decoded
    }

    mutating func decodeNil() throws -> Bool {
        try decode(Bool.self, unboxWith: decoder.unboxNil)
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Bool.self) }) }
    mutating func decode(_ type: String.Type) throws -> String { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: String.self) }) }
    mutating func decode(_ type: Double.Type) throws -> Double { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Double.self) }) }
    mutating func decode(_ type: Float.Type) throws -> Float { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Float.self) }) }
    mutating func decode(_ type: Int.Type) throws -> Int { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Int.self) }) }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Int8.self) }) }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Int16.self) }) }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Int32.self) }) }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: Int64.self) }) }
    mutating func decode(_ type: UInt.Type) throws -> UInt { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: UInt.self) }) }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: UInt8.self) }) }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: UInt16.self) }) }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: UInt32.self) }) }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { let decoder = decoder; return try decode(type, unboxWith: { try decoder.unbox($0, as: UInt64.self) }) }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let decoder = decoder
        return try decode(type, unboxWith: {
            try decoder.unbox($0, as: type)
        })
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        decoder.codingPath.append(IndexKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        guard case let .value(value) = container[currentIndex] else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Found a reference where a value for a nested keyed container was expected.")
        }
        guard case let .keyed(container) = value else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .keyed, reality: value)
        }
        currentIndex += 1
        return KeyedDecodingContainer(KeyedContainerWrapper<NestedKey>(decoder: decoder, container: container))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(IndexKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot get nested unkeyed container -- unkeyed container is at end."))
        }

        guard case let .value(value) = container[currentIndex] else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Found a reference where a value for a nested unkeyed container was expected.")
        }
        guard case let .unkeyed(container) = value else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .unkeyed, reality: value)
        }
        currentIndex += 1
        return UnkeyedContainerWrapper(decoder: decoder, container: container)
    }

    mutating func superDecoder() throws -> Decoder {
        decoder.codingPath.append(IndexKey(index: currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot get super decoder -- unkeyed container is at end."))
        }

        guard case let .value(value) = container[currentIndex] else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Found a reference where a value for a super decoder was expected.")
        }
        currentIndex += 1
        return SuperDecoder(decoder: decoder, container: DecodingContainer(value))
    }
}

extension _Decoder: SingleValueDecodingContainer {
    fileprivate func topContainerSingleValue() throws -> DecodingContainer.Single {
        guard case let .single(container)? = containers.last else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .single, reality: containers.last)
        }
        return container
    }

    func decodeNil() -> Bool {
        guard let container = try? topContainerSingleValue() else {
            return false
        }
        return unboxNil(container)
    }

    func decode(_: Bool.Type) throws -> Bool { try unbox(try topContainerSingleValue(), as: Bool.self) }
    func decode(_: String.Type) throws -> String { try unbox(try topContainerSingleValue(), as: String.self) }
    func decode(_: Double.Type) throws -> Double { try unbox(try topContainerSingleValue(), as: Double.self) }
    func decode(_: Float.Type) throws -> Float { try unbox(try topContainerSingleValue(), as: Float.self) }
    func decode(_: Int.Type) throws -> Int { try unbox(try topContainerSingleValue(), as: Int.self) }
    func decode(_: Int8.Type) throws -> Int8 { try unbox(try topContainerSingleValue(), as: Int8.self) }
    func decode(_: Int16.Type) throws -> Int16 { try unbox(try topContainerSingleValue(), as: Int16.self) }
    func decode(_: Int32.Type) throws -> Int32 { try unbox(try topContainerSingleValue(), as: Int32.self) }
    func decode(_: Int64.Type) throws -> Int64 { try unbox(try topContainerSingleValue(), as: Int64.self) }
    func decode(_: UInt.Type) throws -> UInt { try unbox(try topContainerSingleValue(), as: UInt.self) }
    func decode(_: UInt8.Type) throws -> UInt8 { try unbox(try topContainerSingleValue(), as: UInt8.self) }
    func decode(_: UInt16.Type) throws -> UInt16 { try unbox(try topContainerSingleValue(), as: UInt16.self) }
    func decode(_: UInt32.Type) throws -> UInt32 { try unbox(try topContainerSingleValue(), as: UInt32.self) }
    func decode(_: UInt64.Type) throws -> UInt64 { try unbox(try topContainerSingleValue(), as: UInt64.self) }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try unbox(try topContainerSingleValue(), as: type)
    }
}

private final class SuperDecoder: Decoder {
    let decoder: _Decoder
    private(set) var codingPath: [CodingKey]
    let container: DecodingContainer

    init(decoder: _Decoder, container: DecodingContainer) {
        self.decoder = decoder
        codingPath = decoder.codingPath
        self.container = container
    }

    var userInfo: [CodingUserInfoKey: Any] {
        // SuperDecoder does _not_ conform to CycleBreakerDecoder, and there is no need for it to
        var userInfo = decoder.userInfo
        userInfo[cycleBreakerEncoderUserInfoKey] = nil
        return userInfo
    }

    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case let .keyed(container) = container else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .keyed, reality: self.container)
        }
        return KeyedDecodingContainer(KeyedContainerWrapper(decoder: decoder, container: container))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .unkeyed(container) = container else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .unkeyed, reality: self.container)
        }
        return UnkeyedContainerWrapper(decoder: decoder, container: container)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard case .single = container else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .single, reality: container)
        }
        return self
    }
}

extension SuperDecoder: SingleValueDecodingContainer {
    fileprivate func singleValue() throws -> DecodingContainer.Single {
        guard case let .single(container) = container else {
            throw DecodingError._containerMismatch(at: codingPath, expectation: .single, reality: self.container)
        }
        return container
    }

    func decodeNil() -> Bool {
        guard let container = try? singleValue() else {
            return false
        }
        return decoder.unboxNil(container)
    }

    func decode(_: Bool.Type) throws -> Bool { try decoder.unbox(try singleValue(), as: Bool.self) }
    func decode(_: String.Type) throws -> String { try decoder.unbox(try singleValue(), as: String.self) }
    func decode(_: Double.Type) throws -> Double { try decoder.unbox(try singleValue(), as: Double.self) }
    func decode(_: Float.Type) throws -> Float { try decoder.unbox(try singleValue(), as: Float.self) }
    func decode(_: Int.Type) throws -> Int { try decoder.unbox(try singleValue(), as: Int.self) }
    func decode(_: Int8.Type) throws -> Int8 { try decoder.unbox(try singleValue(), as: Int8.self) }
    func decode(_: Int16.Type) throws -> Int16 { try decoder.unbox(try singleValue(), as: Int16.self) }
    func decode(_: Int32.Type) throws -> Int32 { try decoder.unbox(try singleValue(), as: Int32.self) }
    func decode(_: Int64.Type) throws -> Int64 { try decoder.unbox(try singleValue(), as: Int64.self) }
    func decode(_: UInt.Type) throws -> UInt { try decoder.unbox(try singleValue(), as: UInt.self) }
    func decode(_: UInt8.Type) throws -> UInt8 { try decoder.unbox(try singleValue(), as: UInt8.self) }
    func decode(_: UInt16.Type) throws -> UInt16 { try decoder.unbox(try singleValue(), as: UInt16.self) }
    func decode(_: UInt32.Type) throws -> UInt32 { try decoder.unbox(try singleValue(), as: UInt32.self) }
    func decode(_: UInt64.Type) throws -> UInt64 { try decoder.unbox(try singleValue(), as: UInt64.self) }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try decoder.unbox(try singleValue(), as: type)
    }
}
