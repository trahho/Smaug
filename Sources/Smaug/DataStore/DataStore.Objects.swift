//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

public extension DataStore {
    @propertyWrapper
    final class Objects<Enclosing, T>: ObjectsStorageBase<Enclosing, T> where Enclosing: DataStore, T: Object {
        override var value: Set<T> {
            super.value.filter { $0.added! <= store.document.readingTimestamp }.asSet
        }

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Set<T> {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript(_enclosingInstance instance: Enclosing,
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
