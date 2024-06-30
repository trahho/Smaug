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
        var objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>?
        var objectsKeyPath: ReferenceWritableKeyPath<Value, [Enclosing]>?

        private var deleteReferences: Bool

        override func deleteRelations() {
            guard deleteReferences else { return }
            value.forEach { $0.delete() }
        }

        public init(_ objectKeyPath: ReferenceWritableKeyPath<Value, Enclosing?>, deleteReferences: Bool = false) {
            self.objectKeyPath = objectKeyPath
            self.deleteReferences = deleteReferences
        }

        public init(_ objectsKeyPath: ReferenceWritableKeyPath<Value, [Enclosing]>, deleteReferences: Bool = false) {
            self.objectsKeyPath = objectsKeyPath
            self.deleteReferences = deleteReferences
        }

        private var cancellable: AnyCancellable?

        private var _value: [Value]?
        var value: [Value] {
            get {
                if let _value { return _value }
                guard
                    let document = instance.store?.document
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
                value.asSet.subtracting(newValue).forEach { value in
                    if let objectKeyPath {
                        value[keyPath: objectKeyPath] = nil
                    }
                    if let objectsKeyPath {
                        guard let index = value[keyPath: objectsKeyPath].firstIndex(of: instance) else { return }
                        value[keyPath: objectsKeyPath].remove(at: index)
                    }
                }
                for value in newValue.asSet.subtracting(value) {
                    if let objectKeyPath {
                        value[keyPath: objectKeyPath] = instance
                    }
                    if let objectsKeyPath {
                        value[keyPath: objectsKeyPath].append(instance)
                    }
                }

                _value = newValue
                if let document = instance.store?.document {
                    for value in newValue.asSet.subtracting(value) {
                        if value.added == nil {
                            document.add(value)
                        }
                    }
                }
            }
        }

        override func resetValue() {
            try! withMutation {
                _value = nil
            }
        }

        private weak var _instance: Enclosing?
        private var instance: Enclosing {
            get { _instance! }
            set {
                guard newValue != _instance else { return }
                _instance = newValue
//                cancellable = _instance!.objectWillChange.sink { [self] in
//                    if instance.store?.document != nil {
//                        _value = nil
//                    }
//                }
            }
        }

        override func adopt(document: DatabaseDocument) {
            if let _value { _value.forEach { document.add($0) }}
        }

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: [Value] {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript(_enclosingInstance instance: Enclosing,
                                wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, [Value]>,
                                storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Relations>) -> [Value]
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value
            }
            set {
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
