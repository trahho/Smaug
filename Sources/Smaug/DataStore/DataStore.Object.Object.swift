//
//  Database.Relation.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Combine
import Foundation

public extension DataStore.Object {
    @propertyWrapper final class Object<Value>: ReferenceStorage where Value: ObjectStore.Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value? {
            get { fatalError() }
            set { fatalError() }
        }

        private var _key: String?

        var key: String {
            if let _key { return _key }

            guard let mirror = instance.mirror(for: Self.self).first(where: { $0.value === self }) else { fatalError("wrapper not found") }
            _key = String(mirror.label!.dropFirst())

            return _key!
        }

        private var cancellable: AnyCancellable?

        private var _value: Value?
        var value: Value? {
            get {
                if let _value { return _value }
                guard
                    let document = instance.document,
                    let id = instance[Value.ID.self, key],
                    let value = document[Value.self, id]
                else { return nil }

                _value = value
                return _value
            }
            set {
                guard !instance.readOnly, value != newValue else { return }
                instance[Value.ID.self, key] = newValue?.id
                _value = newValue
                if let document = instance.document, let newValue {
                    document.add(newValue)
                }
            }
        }

        private weak var _instance: DataStore.Object?
        private var instance: DataStore.Object {
            get { _instance! }
            set {
                guard newValue != _instance else { return }
                _instance = newValue
                cancellable = _instance!.objectWillChange.sink { [self] in
                    if instance.document != nil {
                        _value = nil
                    }
                }
            }
        }

        override func adopt(document: DatabaseDocument) {
            if let _value { document.add(_value) }
        }

        public static subscript<Enclosing: DataStore.Object>(_enclosingInstance instance: Enclosing,
                                                             wrapped _: ReferenceWritableKeyPath<Enclosing, Value?>,
                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Object>) -> Value?
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                return storage.value
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.value = newValue
            }
        }

        public init(_ key: String? = nil) {
            self._key = key
        }
    }
}
