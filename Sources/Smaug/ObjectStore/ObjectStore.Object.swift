//
//  PersistentData.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Combine
import Foundation

extension ObjectStore {
    open class Object: IdentifiableObject, ObservableObject, Reflectable, Mergeable {
        var store: ObjectStore?
//        var document: DatabaseDocument? { store?.document }
        public internal(set) var isStatic = false
        
        var added: Date?

        var readOnly: Bool {
            guard let document = store?.document else { return false }
            return document.readOnly || (!document.inSetup && isStatic)
        }
        
        // MARK: - Timing

        var readingTimestamp: Date { store?.readingTimestamp ?? Date.distantFuture }
        var writingTimestamp: Date { store?.writingTimestamp ?? Date.distantPast }

        func adopt(document: DatabaseDocument) {
            mirror(for: ReferenceStorage.self).map { $0.value }.forEach { $0.adopt(document: document) }
        }

        public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
            store![type, id]
        }

        public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
            store![type]
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
        
        open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            if let added, let otherAdded = other.added, otherAdded < added { self.added = other.added }
            
            for (own, other) in zip(mirror(for: ObjectProperty.self), other.mirror(for: ObjectProperty.self)) {
                try own.value.merge(instance: self, other: other.value)
            }
        }
    }
}

