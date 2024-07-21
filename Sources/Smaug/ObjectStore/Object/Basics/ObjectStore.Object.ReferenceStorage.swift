//
//  File.swift
//
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

public extension ObjectStore.Object {
    class ReferenceStorage: ObjectStore.ObjectPropertyWrapper {
        func deleteRelations() {}
        func removeReferences<T>(to _: T) where T: ObjectStore.Object {}
        func adopt(document _: DatabaseDocument) {}
    }
}
