//
//  PersistentData.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation
import Observation

open class ObjectStore: PersistentContent, Restorable, Mergeable, ContentContainer, ObservationInstance, Reflectable {
    // MARK: Nested Types

    // MARK: - Types

    public typealias PersistentValue = Codable & Equatable

    enum Fault: Error {
        case wrongMatch
        case mergeFailed
    }

    // MARK: Properties

    public internal(set) var document: DatabaseDocument!

    // MARK: - Enclosing

    public var objectDidChange: ObjectDidChangePublisher = .init()
    public let observationRegistrar = Observation.ObservationRegistrar()

    // MARK: Computed Properties

    // MARK: - Timing

    public var readingTimestamp: Date { document?.readingTimestamp ?? Date.distantFuture }
    public var writingTimestamp: Date { document?.writingTimestamp ?? Date.distantPast }

    // MARK: Lifecycle

    // MARK: - Initialisation

    public required init() {}

    // MARK: Functions

    public func didChange() {
        objectDidChange.send()
    }

    // MARK: - Persistence

    public func restore() {
        for item in mirror(for: ObjectsStorage.self) {
            item.value.setStore(store: self)
        }
    }

    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { throw MergeError.wrongMatch }

        for (var own, other) in zip(mirror(for: MergeablePropertyWrapper.self), other.mirror(for: MergeablePropertyWrapper.self)) {
            try own.value.merge(other: other.value)
            own.value.setStore(store: self)
        }

        didChange()
    }

    // MARK: - Access

    public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
        document[type, id]
    }

    public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
        document[type]
    }

    public subscript<T, S>(_ type: T.Type, _ ids: S) -> Set<T> where T: ObjectStore.Object, S: Sequence, S.Element == T.ID {
        document[type, ids]
    }

    public func add<T>(_ item: T) where T: ObjectStore.Object {
        document.add(item)
    }

    public func create<T>(_: T.Type) -> T where T: ObjectStore.Object {
        let object = T()
        add(object)
        return object
    }

    public func delete<T>(_ item: T) where T: ObjectStore.Object {
        try! document.deleteObject(item: item)
    }

    public func callAsFunction<T>(_ type: T.Type) -> T where T: ObjectStore.Object {
        create(type)
    }

    public subscript<T>(_ type: T.Type, _ name: String) -> T where T: CacheDatabaseDocument {
        document[type, name]
    }

    // MARK: - Storage

    func storage<T>(type _: T.Type) -> ObjectsStorageAbstract<T>? {
        let storage = mirror(for: ObjectsStorageAbstract<T>.self).first?.value
        if let storage, storage.instance == nil {
            storage.instance = self
        }
        return storage
    }

    func getObject<T>(type: T.Type, id: T.ID) throws -> T? where T: ObjectStore.Object {
        guard let storage = storage(type: type) else { throw DatabaseDocument.Failure.typeNotFound }
        return storage.getObject(id: id)
    }

    func getObjects<T>(type: T.Type) throws -> Set<T> where T: ObjectStore.Object {
        guard let storage = storage(type: type) else { throw DatabaseDocument.Failure.typeNotFound }
        return storage.getObjects()
    }

    func addObject<T>(item: T) throws where T: ObjectStore.Object {
        guard let storage = storage(type: T.self) else { throw DatabaseDocument.Failure.typeNotFound }
        guard storage.getObject(id: item.id) == nil else { return }

//        objectWillChange.send()
        item.added = writingTimestamp
        item.store = self
        item.adopt(document: document)
        storage.addObject(item: item)
        didChange()
    }

    func deleteObject<T>(item: T) throws where T: ObjectStore.Object {
        guard let storage = mirror(for: ObjectsStorageAbstract<T>.self).first?.value else { throw DatabaseDocument.Failure.typeNotFound }
        guard storage.getObject(id: item.id) == item else { return }
        storage.deleteObject(item: item)
        document.removeReferences(to: item)
        item.wasDeleted()
        didChange()
    }

    func removeObject<T>(item: T) throws where T: ObjectStore.Object {
        guard let storage = mirror(for: ObjectsStorageAbstract<T>.self).first?.value else { throw DatabaseDocument.Failure.typeNotFound }
        guard storage.getObject(id: item.id) == item else { return }
        storage.removeObject(item: item)
        didChange()
    }

    func removeReferences<T>(to item: T) where T: ObjectStore.Object {
        for (_, value) in mirror(for: ObjectsStorage.self) {
            if value.instance == nil { value.instance = self }
            value.removeReferences(to: item)
        }
    }
}


