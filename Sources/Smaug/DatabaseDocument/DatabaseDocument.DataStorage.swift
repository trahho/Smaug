//
//  DatabaseDocument.DataStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation

public extension DatabaseDocument {
    class DataStorage: Storage {
        func getObject<T>(type _: T.Type, id _: T.ID) throws -> T? where T: ObjectStore.Object { fatalError("not implemented") }
        func getObjects<T>(type _: T.Type) throws -> Set<T> where T: ObjectStore.Object { fatalError("not implemented") }
        func addObject<T>(item _: T) throws where T: ObjectStore.Object { fatalError("not implemented") }
        func deleteObject<T>(item _: T) throws where T: ObjectStore.Object { fatalError("not implemented") }
        func removeReferences<T>(to _: T) where T: ObjectStore.Object { fatalError("not implemented") }
    }
}
