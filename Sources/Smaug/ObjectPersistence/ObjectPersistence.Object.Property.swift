//
//  File.swift
//
//
//  Created by Guido Kühn on 06.06.24.
//

import Foundation
public extension ObjectPersistence.Object {
    class PropertyBase: ObjectStore.ObjectPropertyWrapper {
        func takeValue(other _: ObjectStore.ObjectPropertyWrapper) {}
    }

    @propertyWrapper final class Property<Value>: PropertyBase where Value: Codable {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        private var _value: Value?
        private var changed: Date?
        weak var instance: ObjectPersistence.Object?

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            self._value as? U
        }

        private func value<U>(_: U.Type) -> U {
            self._value as! U
        }

        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            self._value = wrappedValue()
        }

        public var projectedValue: ObjectStore.ObjectPropertyWrapper {
            self
        }

        override func resetValue() {
            self._value = nil
            self.changed = Date()
        }

        override func takeValue(other: ObjectStore.ObjectPropertyWrapper) {
            guard let other = other as? Self else { return }
            self._value = other._value
        }

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value where Enclosing: ObjectPersistence.Object
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
                    storage.changed = Date()
                }
            }
        }
    }
}

extension ObjectPersistence.Object.Property: MergeablePropertyWrapper {
    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }
        if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
            try withMutation {
                changed = otherChanged
                if var ownValue = _value as? Mergeable, let otherValue = other._value as? Mergeable {
                    try ownValue.merge(other: otherValue)
                } else {
                    _value = other._value
                }
            }
        }
    }
}

public extension Array where Array.Element: ObjectPersistence.Object {
    mutating func removeItem(_ item: Element) {
        guard let index = self.firstIndex(of: item) else { return }
        self.remove(at: index)
    }
}

extension Array: Mergeable where Array.Element: ObjectPersistence.Object {
    func firstIndex(of other: ObjectPersistence.Object, at index: Index) -> Index? {
        let objects = self.filter { $0.id == other.id }

        guard !objects.isEmpty else { return nil }

        return objects.compactMap { self.firstIndex(of: $0) }.first { $0 >= index }
    }

    public mutating func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }

        for otherIndex in other.indices {
            let other = other[otherIndex]
            guard let myIndex = self.firstIndex(of: other, at: otherIndex) else {
                self.insert(other, at: otherIndex)
                continue
            }
            let my = self.remove(at: myIndex)
            try my.merge(other: other)
            self.insert(my, at: otherIndex)
        }
        if self.count > other.count {
            self.removeLast(self.count - other.count)
        }
    }
}

extension ObjectPersistence.Object.Property: PersistentProperty {
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
