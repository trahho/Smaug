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

        // MARK: Overridden Functions

//        func configureObservation<Enclosing>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, Set<T>>) where Enclosing: ObjectStore {
//            withMutation = { action in
//                instance.objectWillChange.send()
//                try instance._$observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
//                instance.objectDidChange.send()
//            }
//            showAccess = {
//                instance._$observationRegistrar.access(instance, keyPath: keyPath)
//            }
//        }

//        override func contains(id: UUID) -> Bool {
//            getObject(id: id) != nil
//        }

        // MARK: Functions

        func getObject(id _: T.ID) -> T? { fatalError() }

        func getObjects() -> Set<T> { fatalError() }

        func addObject(item _: T) { fatalError() }

        func deleteObject(item _: T) { fatalError() }
    }
}
