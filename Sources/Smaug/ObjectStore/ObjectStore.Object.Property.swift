//
//  Database.Property.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

public extension ObjectStore.Object {
//    @propertyWrapper final class Property<Value> where Value: DataStore.PersistentValue {
//        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
//        public var wrappedValue: Value {
//            get { fatalError() }
//            set { fatalError() }
//        }
//
//        private var defaultValue: (() -> Value)?
//        private var value: Value?
//
//        public init(wrappedValue: @autoclosure @escaping () -> Value) {
//            defaultValue = wrappedValue
//        }
//
//        public init() {}
//
//        public static subscript<Enclosing: ObjectStore.Object>(_enclosingInstance instance: Enclosing,
//                                                               wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
//                                                               storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
//        {
//            get {
//                let storage = instance[keyPath: storageKeyPath]
//                if let value = storage.value {
//                    return value
//                } else {
//                    return storage.defaultValue!()
//                }
//            }
//            set {
//                guard !instance.readOnly else { return }
//                let storage = instance[keyPath: storageKeyPath]
//                storage.value = newValue
//            }
//        }
//    }
    // }
//
    // public extension ContentStore {

    class ObjectProperty {
        var changed: Date?

        public init() {}

        func merge(instance _: ObjectStore.Object, other _: ObjectProperty) throws {}
    }

    @propertyWrapper final class Property<Value>: ObjectProperty where Value: Codable {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        private var _value: Value?

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            _value as? U
        }

        private func value<U>(_: U.Type) -> U {
            _value as! U
        }

        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            _value = wrappedValue()
        }

        public static subscript<Enclosing: ObjectStore.Object>(_enclosingInstance instance: Enclosing,
                                                               wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
                                                               storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                instance.objectWillChange.send()
                storage._value = newValue
                storage.changed = instance.writingTimestamp
                instance.store?.objectDidChange.send()
            }
        }

        override func merge(instance: ObjectStore.Object, other: ObjectProperty) throws {
            guard let other = other as? Self else { return }
            if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
                instance.objectWillChange.send()
                _value = other._value
            }
        }
    }
}

extension ObjectStore.Object.Property: EncodableProperty {
    struct Coded: Codable {
        var value: Value?
        var changed: Date
    }

    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
        guard let changed else { return }
        let codingKey = SerializedCodingKeys(key: propertyName)
        try container.encodeIfPresent(Coded(value: _value, changed: changed), forKey: codingKey)
    }
}

extension ObjectStore.Object.Property: DecodableProperty {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: propertyName)
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: codingKey) {
            _value = coded.value
            changed = coded.changed
        }
    }
}
