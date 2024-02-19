//
//  Database.Relation.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Object<Value>: ReferenceStorage where Value: ObjectStore.Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value? {
            get { fatalError() }
            set { fatalError() }
        }

        private var cancellable: AnyCancellable?

        private var _id: Value.ID?
        private var _value: Value?
        private var changed: Date?

        private weak var _instance: ObjectStore.Object?

        var value: Value? {
            get {
                if let _value { return _value }
                guard
                    let document = instance.store?.document,
                    let id = _id,
                    let value = document[Value.self, id]
                else { return nil }

                _value = value
                return _value
            }
            set {
                guard !instance.readOnly, value != newValue else { return }
                _id = newValue?.id
                _value = newValue
                changed = instance.writingTimestamp
                if let document = instance.store?.document, let newValue {
                    document.add(newValue)
                }
            }
        }

        private var instance: ObjectStore.Object {
            get { _instance! }
            set {
                guard newValue != _instance else { return }
                _instance = newValue
                cancellable = _instance!.objectWillChange.sink { [self] in
                    if instance.store?.document != nil {
                        _value = nil
                    }
                }
            }
        }

        override func adopt(document: DatabaseDocument) {
            if let _value { document.add(_value) }
        }

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value?>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Object>) -> Value? where Enclosing: ObjectStore.Object
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value
            }
            set {
                guard !instance.readOnly else { return }
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage.value = newValue
                }
            }
        }
    }
}

extension ObjectStore.Object.Object: Mergeable {
    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }
        if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
            try withMutation {
                changed = otherChanged
                _id = other._id
                _value = nil
            }
        }
    }
}

extension ObjectStore.Object.Object: EncodableProperty {
    struct Coded: Codable {
        var value: Value.ID?
        var changed: Date
    }

    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
        guard let changed else { return }
        let codingKey = SerializedCodingKeys(key: propertyName)
        try container.encodeIfPresent(Coded(value: _id, changed: changed), forKey: codingKey)
    }
}

extension ObjectStore.Object.Object: DecodableProperty {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: propertyName)
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: codingKey) {
            _id = coded.value
            changed = coded.changed
        }
    }
}
