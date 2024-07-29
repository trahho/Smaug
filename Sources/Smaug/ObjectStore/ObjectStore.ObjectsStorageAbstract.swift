//
//  File.swift
//
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation

public extension ObjectStore {
    class ObjectsStorageAbstract<T>: ObjectsStorage where T: Object {
        // MARK: Properties

        // MARK: - Key

        var deletedTimestamp: Date?

        // MARK: Computed Properties

        var value: Set<T> { fatalError() }

        // MARK: Functions

        func getObject(id _: T.ID) -> T? { fatalError() }

        func getObjects() -> Set<T> { fatalError() }

        func addObject(item _: T) { fatalError() }

        func deleteObject(item _: T) { fatalError() }

        func removeObject(item _: T) { fatalError() }
    }
}
