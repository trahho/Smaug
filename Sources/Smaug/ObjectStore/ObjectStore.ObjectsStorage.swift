//
//  ObjectStore.ObjectsStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation

public extension ObjectStore {
    class ObjectsStorage: Mergeable {
        public func setStore(store: ObjectStore) {}
        public func merge(other: Mergeable) throws {}
        var store: ObjectStore!
        public init() {}
    }
}
