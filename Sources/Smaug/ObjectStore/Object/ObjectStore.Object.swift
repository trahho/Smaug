//
//  PersistentData.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Combine
import Foundation
import Observation


extension ObjectStore {
    open class Object: ObjectBase {
        var store: ObjectStore?
//        var document: DatabaseDocument? { store?.document }
        public internal(set) var isStatic = false

        var added: Date?

        var readOnly: Bool {
            guard let document = store?.document else { return false }
            return document.readOnly || (!document.inSetup && isStatic)
        }

        // MARK: - Timing

        public var readingTimestamp: Date { store?.readingTimestamp ?? Date.distantFuture }
        public var writingTimestamp: Date { store?.writingTimestamp ?? Date.distantPast }

        func adopt(document: DatabaseDocument) {
            mirror(for: ReferenceStorage.self).map {
                $0.value
            }.forEach {
                $0.adopt(document: document)
            }
        }

        public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
            store![type, id]
        }

        public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
            store![type]
        }

        public subscript<T, S>(_ type: T.Type, _ ids: S) -> Set<T> where T: ObjectStore.Object, S: Sequence, S.Element == T.ID {
            store![type, ids]
        }

        public func add<T>(_ item: T) where T: ObjectStore.Object {
            store!.add(item)
        }

        public func callAsFunction<T>(_ type: T.Type) -> T where T: ObjectStore.Object {
            store!.create(type)
        }

        public subscript<T>(_ type: T.Type, _ name: String) -> T where T: DatabaseDocument {
            store![type, name]
        }

        public func delete() {
            try! store!.deleteObject(item: self)
        }

        override public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: PersistentCodingKey.self)
            try container.encode(added, forKey: PersistentCodingKey(key: "ADDED"))
            try super.encode(to: encoder)
        }

        override public func decode(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: PersistentCodingKey.self)
            try added = container.decode(Date.self, forKey: PersistentCodingKey(key: "ADDED"))
            try super.decode(from: decoder)
        }

        override open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            if let added, let otherAdded = other.added, otherAdded < added { self.added = other.added }

            try super.merge(other: other)
        }
    }
}
