//
//  PersistentData.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Combine
import Foundation

extension ObjectStore {
    open class Object: PersistentObject, ObservableObject, Reflectable {
        var store: ObjectStore?
        var document: DatabaseDocument? { store?.document }
        public internal(set) var isStatic = false

        var readOnly: Bool {
            if let document {
                return document.readOnly || (!document.inSetup && isStatic)
            } else { return false }
        }

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
    }
}
