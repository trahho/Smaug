//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Relations<Enclosing, Value>: ReferenceStorage where Value: ObjectStore.Object, Enclosing: ObjectStore.Object {
        private var objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>?
        private var objectsKeyPath: ReferenceWritableKeyPath<Value, Set<Enclosing>>?

        public init(_ objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>) {
            self.objectKeyPath = objectKeyPath
        }

        public init(_ objectsKeyPath: ReferenceWritableKeyPath<Value, Set<Enclosing>>) {
            self.objectsKeyPath = objectsKeyPath
        }

        private var cancellable: AnyCancellable?

        private var _value: Set<Value>?
        var value: Set<Value> {
            get {
                if let _value { return _value }
                guard
                    let document = instance.document
                else { return [] }
                if let objectKeyPath {
                    _value = document[Value.self].filter { $0[keyPath: objectKeyPath] == instance }
                }
                if let objectsKeyPath {
                    _value = document[Value.self].filter { $0[keyPath: objectsKeyPath].contains(instance) }
                }
                return _value ?? []
            }
            set {
                guard !instance.readOnly else { return }
                let value = value
                value.subtracting(newValue).forEach { value in
                    if let objectKeyPath {
                        value[keyPath: objectKeyPath] = nil
                    }
                    if let objectsKeyPath {
                        value[keyPath: objectsKeyPath].remove(instance)
                    }
                }
                newValue.subtracting(value).forEach { value in
                    if let objectKeyPath {
                        value[keyPath: objectKeyPath] = instance
                    }
                    if let objectsKeyPath {
                        value[keyPath: objectsKeyPath].insert(instance)
                    }
                }

                _value = newValue
                if let document = instance.document {
                    newValue.subtracting(value).forEach { value in
                        document.add(value)
                    }
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
            if let _value { _value.forEach { document.add($0) }}
        }

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Set<Value> {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript(_enclosingInstance instance: Enclosing,
                                wrapped _: ReferenceWritableKeyPath<Enclosing, Set<Value>>,
                                storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Relations>) -> Set<Value>
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
