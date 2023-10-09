//
//  PersistentData.Storage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation

public extension ObjectMemory {
    @propertyWrapper
    final class Objects<T>: ObjectsStorageAbstract<T> where T: Object {
        // MARK: - Types

        struct Cache {
            weak var object: T?
        }

        typealias StorageDictionary = [T.ID: Cache]

        // MARK: - Wrapping

        public var wrappedValue: Set<T> {
            get {
                getObjects()
            }
            set {}
        }

        // MARK: - Restoration

        override public func merge(other: Mergeable) throws {}

        override public func setStore(store: ObjectStore) {
            self.store = store
            storage.filter { $0.value.object == nil }.forEach { storage.removeValue(forKey: $0.key) }
            storage.values.forEach { $0.object?.store = store }
        }

        // MARK: - Storage

        var storage: StorageDictionary = [:]

        override func getObject(id: T.ID) -> T? {
            storage[id]?.object
        }

        override func getObjects() -> Set<T> {
            Set(storage.values.compactMap { $0.object })
        }

        override func addObject(item: T) {
            guard storage[item.id] == nil else { return }
            storage[item.id] = Cache(object:item)
        }
    }
}
