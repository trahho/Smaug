//
//  File.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation

public extension PropertyStore {
    @propertyWrapper final class Property<Value> where Value: Codable {
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

        public init() {}

        public static subscript<Enclosing: PropertyStore>(_enclosingInstance instance: Enclosing,
                                                          wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
                                                          storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                print("Contentstore.Property will change")
                instance.objectWillChange.send()
                storage._value = newValue
                instance.objectDidChange.send()
            }
        }
    }
}

extension PropertyStore.Property: PersistentProperty {
    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        try container.encodeIfPresent(_value, forKey: key)
    }

    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        _value = try? container.decodeIfPresent(Value.self, forKey: key)
    }
}
