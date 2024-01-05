//
//  File.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation

public extension ContentStore {
    @propertyWrapper final class Property<Value> where Value: Codable {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        var key: String?
        var alternateKey: String?

        private var _value: Value?

        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            _value as? U
        }

        private func value<U>(_: U.Type) -> U {
            _value as! U
        }

        public init(wrappedValue: @autoclosure @escaping () -> Value, _ key: String? = nil, alternateKey: String? = nil) {
            self.key = key
            self.alternateKey = alternateKey
            _value = wrappedValue()
        }

        public init(_ key: String? = nil, alternateKey: String? = nil) {
            self.key = key
            self.alternateKey = alternateKey
            _value = nil
        }

        public init() {}

        public static subscript<Enclosing: ContentStore>(_enclosingInstance instance: Enclosing,
                                                         wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
                                                         storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                print ("Contentstore.Property will change")
                instance.objectWillChange.send()
                storage._value = newValue
                instance.objectDidChange.send()
            }
        }
    }
}

extension ContentStore.Property: EncodableProperty {
    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
        guard let _value else { return }
        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
        try container.encodeIfPresent(_value, forKey: codingKey)
    }
}

extension ContentStore.Property: DecodableProperty {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
        if let value = try? container.decodeIfPresent(Value.self, forKey: codingKey) {
            _value = value
        } else {
            guard let altKey = alternateKey else { return }
            let altCodingKey = SerializedCodingKeys(key: altKey)
            if let value = try? container.decodeIfPresent(Value.self, forKey: altCodingKey) {
                _value = value
            }
        }
    }
}
