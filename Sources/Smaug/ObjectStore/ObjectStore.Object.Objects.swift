//
//  Database.Object.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Objects<Value>: ReferenceStorage where Value: ObjectStore.Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Set<Value> {
            get { fatalError() }
            set { fatalError() }
        }

        private var cancellable: AnyCancellable?

        private var _ids: Set<Value.ID>?
        private var _value: Set<Value>?
        var value: Set<Value> {
            get {
                if let _value { return _value }
                guard
                    let database = instance.document,
                    let ids = _ids
                else { return [] }

                _value = ids.compactMap { database[Value.self, $0] }.asSet
                return _value!
            }
            set {
                guard !instance.readOnly,  value != newValue else { return }
                instance.objectWillChange.send()
                _ids = newValue.map { $0.id }.asSet
                _value = newValue
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
            if let _value { _value.forEach { document.add($0) }}
        }

        public static subscript<Enclosing: ObjectStore.Object>(_enclosingInstance instance: Enclosing,
                                                               wrapped _: ReferenceWritableKeyPath<Enclosing, Set<Value>>,
                                                               storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Objects>) -> Set<Value>
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
