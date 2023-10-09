//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Relation<Enclosing, Value>: ReferenceStorage where Value: ObjectStore.Object, Enclosing: ObjectStore.Object {
        private var objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>?
        private var objectsKeyPath: ReferenceWritableKeyPath<Value, Set<Enclosing>>?

        public init(_ objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>) {
            self.objectKeyPath = objectKeyPath
        }

        public init(_ objectsKeyPath: ReferenceWritableKeyPath<Value, Set<Enclosing>>) {
            self.objectsKeyPath = objectsKeyPath
        }

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value? {
            get { fatalError() }
            set { fatalError() }
        }

        private var cancellable: AnyCancellable?

        private var _value: Value?
        var value: Value? {
            get {
                if let _value { return _value }
                guard
                    let document = instance.document
                else { return nil }
                if let objectKeyPath {
                    _value = document[Value.self].first(where: { $0[keyPath: objectKeyPath] == instance })
                }
                if let objectsKeyPath {
                    _value = document[Value.self].first(where: { $0[keyPath: objectsKeyPath].contains(instance) })
                }
                return _value
            }
            set {
                guard !instance.readOnly,  value != newValue else { return }
                if let objectKeyPath {
                    if let value { value[keyPath: objectKeyPath] = nil }
                    if let newValue { newValue[keyPath: objectKeyPath] = instance }
                }
                if let objectsKeyPath {
                    if let value { value[keyPath: objectsKeyPath].remove(instance) }
                    if let newValue { newValue[keyPath: objectsKeyPath].insert(instance) }
                }
                _value = newValue
                if let document = instance.document, let newValue {
                    document.add(newValue)
                }
            }
        }

        private weak var _instance: Enclosing?
        private var instance: Enclosing {
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

        public static subscript(_enclosingInstance instance: Enclosing,
                                wrapped _: ReferenceWritableKeyPath<Enclosing, Value?>,
                                storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Relation>) -> Value?
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
