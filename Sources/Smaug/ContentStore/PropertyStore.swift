//
//  ContentStore.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation
import Observation

open class PropertyStore: PersistentContent, ContentContainer, ObservationInstance, Reflectable {
    // MARK: Nested Types

    // MARK: - Types

    public typealias PersistentValue = Codable & Equatable

    // MARK: Properties

    // MARK: - Enclosing

    public var objectDidChange: ObjectDidChangePublisher = .init()
    public let observationRegistrar = ObservationRegistrar()

    public internal(set) var document: DatabaseDocument!

    // MARK: Lifecycle

    // MARK: - Initialisation

    public required init() {}

    // MARK: Functions

    public func didChange() {
        objectDidChange.send()
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

    public func create<T>(_: T.Type) -> T where T: ObjectStore.Object {
        let object = T()
        add(object)
        return object
    }

    public subscript<T>(_ type: T.Type, _ name: String) -> T where T: CacheDatabaseDocument {
        document[type, name]
    }
}

extension PropertyStore: Persistent {
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
