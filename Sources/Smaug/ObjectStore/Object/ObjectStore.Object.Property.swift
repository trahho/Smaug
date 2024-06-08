//
//  Database.Property.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Property<Value>: ObservationPropertyWrapper where Value: Codable {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        private var _value: Value?
        private var defaultValue: (() -> Value)?
        private var changed: Date?
        weak var instance: ObjectStore.Object?

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            if let defaultValue, _value == nil {
                return defaultValue() as? U
            }
            return _value as? U
        }

        private func value<U>(_: U.Type) -> U {
            if let defaultValue, _value == nil {
                return defaultValue() as! U
            }
            return _value as! U
        }

        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            defaultValue = wrappedValue
        }

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value where Enclosing: ObjectStore.Object
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value(Value.self)
            }
            set {
                guard !instance.readOnly else { return }
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage._value = newValue
                    storage.changed = instance.writingTimestamp
                }
                instance.store?.objectDidChange.send()
            }
        }
    }
}

extension ObjectStore.Object.Property: MergeablePropertyWrapper {
    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }
        if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
            try withMutation {
                changed = otherChanged
                if var ownValue = _value as? Mergeable, let otherValue = other._value as? Mergeable {
                    try ownValue.merge(other: otherValue)
                    _value = ownValue as? Value
                } else {
                    _value = other._value
                }
            }
        }
    }
}

extension ObjectStore.Object.Property: PersistentProperty {
    struct Coded: Codable {
        var value: Value?
        var changed: Date
    }

    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        guard let changed else { return }
        try container.encodeIfPresent(Coded(value: _value, changed: changed), forKey: key)
    }

    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: key) {
            _value = coded.value
            changed = coded.changed
        }
    }
}
