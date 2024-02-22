//
//  PersistentData.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation
import Observation

open class ObjectStore: PersistentContent, Restorable, Mergeable, ContentContainer, ObservationInstance, Reflectable {
    // MARK: - Types

    public typealias PersistentValue = Codable & Equatable

    enum Fault: Error {
        case wrongMatch
        case mergeFailed
    }

    public internal(set) var document: DatabaseDocument!

    // MARK: - Timing

    var readingTimestamp: Date { document?.readingTimestamp ?? Date.distantFuture }
    var writingTimestamp: Date { document?.writingTimestamp ?? Date.distantPast }

    // MARK: - Enclosing

    public var objectDidChange: ObjectDidChangePublisher = .init()
    public let observationRegistrar = Observation.ObservationRegistrar()

    // MARK: - Initialisation

    public required init() {}

    // MARK: - Persistence

    public func restore() {
        let mirror = mirror(for: ObjectsStorage.self)
        mirror.forEach {
            $0.value.setStore(store: self)
        }
    }

    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { throw MergeError.wrongMatch }

        for (own, other) in zip(mirror(for: ObjectsStorage.self), other.mirror(for: ObjectsStorage.self)) {
            try own.value.merge(other: other.value)
            own.value.setStore(store: self)
        }
    }

    // MARK: - Storage

    func storage<T>(type: T.Type) -> ObjectsStorageAbstract<T>? {
        mirror(for: ObjectsStorageAbstract<T>.self).first?.value
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
        storage.addObject(item: item)
        item.added = writingTimestamp
        item.store = self
        item.adopt(document: document)
//        objectDidChange.send()
    }

    func deleteObject<T>(item: T) throws where T: ObjectStore.Object {
        guard let storage = storage(type: T.self) else { throw DatabaseDocument.Failure.typeNotFound }
        guard storage.getObject(id: item.id) == item else { return }

        storage.deleteObject(item: item)
    }

    // MARK: - Access

    public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
        document[type, id]
    }

    public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
        document[type]
    }

    public func add<T>(_ item: T) where T: ObjectStore.Object {
        document.add(item)
    }

    public func create<T>(_ type: T.Type) -> T where T: ObjectStore.Object {
        let object = T()
        add(object)
        return object
    }

    public subscript<T>(_ type: T.Type, _ name: String) -> T where T: DatabaseDocument {
        document[type, name]
    }
}

extension ObjectStore: Persistent {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PersistentCodingKey.self)

        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.encode(into: &container, key: PersistentCodingKey(key: label))
            }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PersistentCodingKey.self)

        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.decode(from: container, key: PersistentCodingKey(key: label))
            }
    }
}
