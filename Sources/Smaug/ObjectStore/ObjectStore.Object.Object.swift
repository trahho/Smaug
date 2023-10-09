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
        var value: Value? {
            get {
                if let _value { return _value }
                guard
                    let document = instance.document,
                    let id = _id,
                    let value = document[Value.self, id]
                else { return nil }

                _value = value
                return _value
            }
            set {
                guard !instance.readOnly, value != newValue else { return }
                instance.objectWillChange.send()
                _id = newValue?.id
                _value = newValue
                if let document = instance.document, let newValue {
                    document.add(newValue)
                }
            }
        }

        private weak var _instance: ObjectStore.Object?
        private var instance: ObjectStore.Object {
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

        public static subscript<Enclosing: ObjectStore.Object>(_enclosingInstance instance: Enclosing,
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
    }
}
