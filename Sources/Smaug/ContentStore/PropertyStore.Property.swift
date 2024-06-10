//
//  File.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation

public extension PropertyStore {
    @propertyWrapper final class Property<Value>: ObservationPropertyWrapper where Value: Codable {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        private var _value: Value?
        private var defaultValue: (() -> Value)?
        private var changed: Date?

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            _value as? U
        }

        private func value<U>(_: U.Type) -> U {
            _value as! U
        }

        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            _value = wrappedValue()
        }

        public static subscript<Enclosing: PropertyStore>(_enclosingInstance instance: Enclosing,
                                                          wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
                                                          storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage._value = newValue
                    storage.changed = Date()
                }
                instance.didChange()
            }
        }
    }
}

extension PropertyStore.Property: MergeablePropertyWrapper {
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


extension PropertyStore.Property: PersistentProperty {
    struct Coded: Codable {
        var value: Value?
        var changed: Date
    }

    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        guard let changed else { return }
        try container.encodeIfPresent(Coded(value: _value, changed: changed), forKey: key)
    }

    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        guard let coded = try? container.decodeIfPresent(Coded.self, forKey: key) else { return }
        _value = coded.value
        changed = coded.changed
    }
}
