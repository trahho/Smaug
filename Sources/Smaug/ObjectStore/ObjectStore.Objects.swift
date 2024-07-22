//
//  PersistentData.Storage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation

public extension ObjectStore {
    @propertyWrapper
    final class Objects<Value>: ObjectsStorageBase<Value> where Value: Object {
        // MARK: Computed Properties

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Set<Value> {
            get { fatalError() }
            set { fatalError() }
        }

        // MARK: Overridden Functions

        override func removeReferences<T>(to item: T) where T: ObjectStore.Object {
            for storedItem in value {
                let wrappers = storedItem.mirror(for: ObjectStore.Object.ReferenceStorage.self)
                for (_, value) in wrappers {
                    value.removeReferences(to: item)
                }
            }
        }

        // MARK: Static Functions

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Set<Value>>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Objects>) -> Set<Value>
            where Enclosing: ObjectStore
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value
            }
            set {}
        }
    }
}
