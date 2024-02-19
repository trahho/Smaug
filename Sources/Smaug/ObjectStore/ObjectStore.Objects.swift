//
//  PersistentData.Storage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation

public extension ObjectStore {
    @propertyWrapper
    final class Objects<T>: ObjectsStorageBase<T> where T: Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Set<T> {
            get { fatalError() }
            set { fatalError() }
        }
        
        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Set<T>>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Objects>) -> Set<T>
            where Enclosing: ObjectStore
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.withMutation = { action in
                    instance.objectWillChange.send()
                    instance._$observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath, action)
                    instance.objectDidChange.send()
                }
                instance._$observationRegistrar.access(instance, keyPath: wrappedKeyPath)
                return storage.value
            }
            set {}
        }
    }
}
