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
        
        
        
        public static subscript<Enclosing: ObjectStore>(_enclosingInstance instance: Enclosing,
                                                      wrapped _: ReferenceWritableKeyPath<Enclosing, Set<T>>,
                                                      storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Objects>) -> Set<T>
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                return storage.value
            }
            set {}
        }
    }
}
