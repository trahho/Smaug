//
//  Property.swift
//  Smaug
//
//  Created by Guido Kühn on 29.07.24.
//

import Foundation

public extension ObjectStore {
    @propertyWrapper
    final class Property<Value>: ObservationPropertyWrapper, MergeablePropertyWrapper where Value: Codable {
        // MARK: Properties

        weak var instance: ObjectStore?

        private var changed: Date?
        private let id = UUID()

        // MARK: Computed Properties

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        private var _value: Value? 

        // MARK: Lifecycle

        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            print("init wrappedValue: \(String(describing: wrappedValue()))")
            _value = wrappedValue()
        }

        // MARK: Static Functions

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value where Enclosing: ObjectStore
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage._value = newValue
                    storage.changed = instance.writingTimestamp
                }
                instance.didChange()
            }
        }

        // MARK: Functions

        public func merge(other: any Mergeable) throws {
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

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            _value as? U
        }

        private func value<U>(_: U.Type) -> U {
            _value as! U
        }
    }
}

extension ObjectStore.Property: PersistentProperty {
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
