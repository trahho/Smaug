//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

public extension ObjectStore {
    class ObjectsStorageBase<T>: ObjectsStorageAbstract<T> where T: Object {
        // MARK: Nested Types

        // MARK: - Types

        typealias StorageDictionary = [T.ID: T]

        // MARK: Overridden Properties

        override var value: Set<T> {
            instance.document[T.self]
        }

        // MARK: Properties

        // MARK: - Storage

        var storage: StorageDictionary = [:]

        // MARK: Overridden Functions

        // MARK: - Restoration

        override public func merge(other: Mergeable) throws {
            guard let other = other as? Self else { return }
            try mergeItems(other)
            try withMutation {
                importItems(other)
                deleteItems(other)
            }
        }

        override public func setStore(store: ObjectStore) {
            self.store = store
            storage.values.forEach { $0.store = store }
        }

        override func getObject(id: T.ID) -> T? {
            showAccess()
            return storage[id]
        }

        override func getObjects() -> Set<T> {
            showAccess()
            return Set(storage.values)
        }

        override func addObject(item: T) {
            guard storage[item.id] == nil else { return }
            try! withMutation {
                storage[item.id] = item
            }
        }

        override func deleteObject(item: T) {
            try! withMutation {
                removeObject(item: item)
            }
        }

        override func removeObject(item: T) {
            guard storage[item.id] == item else { return }
            if let added = item.added, added < instance.writingTimestamp {
                deletedTimestamp = max(added, deletedTimestamp ?? .distantPast)
            }
            storage.removeValue(forKey: item.id)
        }

        // MARK: Functions

        fileprivate func mergeItems(_ other: ObjectStore.ObjectsStorageBase<T>) throws {
            try Set(storage.keys).intersection(Set(other.storage.keys))
                .forEach { key in
                    let ownMergeable = storage[key]!
                    let otherMergeable = other.storage[key]!
                    try ownMergeable.merge(other: otherMergeable)
                }
        }

        fileprivate func importItems(_ other: ObjectStore.ObjectsStorageBase<T>) {
            Set(other.storage.keys).subtracting(Set(storage.keys))
                .compactMap { other.storage[$0] }
                .filter { $0.added! > deletedTimestamp ?? .distantPast }
                .forEach {
                    storage[$0.id] = $0
                }
        }

        fileprivate func deleteItems(_ other: ObjectStore.ObjectsStorageBase<T>) {
            guard let otherDeletedTimestamp = other.deletedTimestamp else { return }
            Set(storage.keys).subtracting(Set(other.storage.keys))
                .compactMap { storage[$0] }
                .filter { $0.added! <= otherDeletedTimestamp }
                .forEach {
                    storage.removeValue(forKey: $0.id)
                }
            if otherDeletedTimestamp > deletedTimestamp ?? .distantPast {
                deletedTimestamp = otherDeletedTimestamp
            }
        }
    }
}
