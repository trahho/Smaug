//
//  ObjectStore.ObjectsStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation

public extension ObjectStore {
    class ObjectsStorage: ObservationPropertyWrapper, MergeablePropertyWrapper {
        // MARK: Properties

        public internal(set) var store: ObjectStore!

        var instance: ObjectStore!

        // MARK: Functions

        public func setStore(store _: ObjectStore) {}
        public func merge(other _: Mergeable) throws {}

//        func contains(id _: UUID) -> Bool { false }
        func removeReferences<T>(to _: T) where T: ObjectStore.Object {}
    }
}
